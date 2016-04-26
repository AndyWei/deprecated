/*
 * auth.go
 * auth related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package auth

import (
    "encoding/json"
    "github.com/gocql/gocql"
    "github.com/spf13/viper"
    "golang.org/x/crypto/bcrypt"
    "joyyapp.com/winkrock/idgen"
    . "joyyapp.com/winkrock/util"
    "net/http"
)

type Handler struct {
    DB *gocql.Session
}

var (
    kBcryptCost int    = 0
    kImDomain   string = ""
    kTokenTtl   int    = 0
)

func init() {

    viper.SetConfigName("config")
    viper.SetConfigType("toml")
    viper.AddConfigPath("/etc/winkrock/")
    err := viper.ReadInConfig()
    LogPanic(err)

    kBcryptCost = viper.GetInt("bcrypt.cost")
    kImDomain = viper.GetString("im.domain")
    kTokenTtl = viper.GetInt("jwt.tokenExpiresInMins") * 60
}

/*
 * Signup/Signin request and response structure
 */
type AuthParams struct {
    Username string `param:"username" validate:"min=2,max=40"`
    Password string `param:"password" validate:"min=2,max=40"`
}

type AuthResponse struct {
    Username string `json:"username"`
    Id       int64  `json:"userid"`
    YRS      int64  `json:"yrs"`
    Token    string `json:"token"`
    TokenTtl int    `json:"token_ttl"`
}

func (h *Handler) SignUp(w http.ResponseWriter, req *http.Request) {

    var p AuthParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    epassword, err := bcrypt.GenerateFromPassword([]byte(p.Password), kBcryptCost)
    userid := idgen.NewID()

    // write DB. note lightweight transaction is used to make sure the username is unique
    applied, err := h.DB.Query(`INSERT INTO user_by_name (username, userid, password) VALUES (?, ?, ?) IF NOT EXISTS`,
        p.Username, userid, epassword).ScanCAS()
    if err != nil || !applied {
        RespondError(w, ErrUsernameConflict, http.StatusBadRequest)
        return
    }

    if err := h.DB.Query(`INSERT INTO user (userid, username, deleted) VALUES (?, ?, false)`,
        userid, p.Username).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    // create JWT token
    token, err := NewToken(userid, p.Username)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    // success
    LogInfof("New user signed up. userid = %v, username = %v\n\r", userid, p.Username)

    response := &AuthResponse{
        Username: p.Username,
        Id:       userid,
        YRS:      int64(0),
        Token:    token,
        TokenTtl: kTokenTtl,
    }

    bytes, _ := json.Marshal(response)
    RespondData(w, bytes)
    return
}

/*
 * Signin endpoint
 */

func (h *Handler) SignIn(w http.ResponseWriter, req *http.Request) {

    var p AuthParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    // read encrypted password from DB
    var userid int64
    var epassword string
    var yrs int64
    if err := h.DB.Query(`SELECT userid, password, yrs FROM user_by_name WHERE username = ? LIMIT 1`,
        p.Username).Consistency(gocql.One).Scan(&userid, &epassword, &yrs); err != nil {
        RespondError(w, ErrUserNotExist, http.StatusBadRequest)
        return
    }

    // check password
    if err := bcrypt.CompareHashAndPassword([]byte(epassword), []byte(p.Password)); err != nil {
        RespondError(w, ErrPasswordInvalid, http.StatusUnauthorized)
        return
    }

    // success
    token, err := NewToken(userid, p.Username)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    response := &AuthResponse{
        Username: p.Username,
        Id:       userid,
        YRS:      yrs,
        Token:    token,
        TokenTtl: kTokenTtl,
    }

    bytes, _ := json.Marshal(response)
    RespondData(w, bytes)
    return
}

/*
 * XMPP CheckExistence request structure
 */
type CheckExistenceParams struct {
    UserId int64  `param:"user" validate:"required"`
    Server string `param:"server" validate:"required"`
    Token  string `param:"pass"`
}

func (h *Handler) CheckExistence(w http.ResponseWriter, req *http.Request) {

    var p CheckExistenceParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    if p.Server != kImDomain {
        RespondError(w, ErrIMServerInvalid, http.StatusBadRequest)
        return
    }

    // To avoid DB pressure, skip reading
    // read DB
    // var deleted bool
    // err := h.DB.Query(`SELECT deleted FROM user WHERE userid = ? LIMIT 1`,
    //     p.UserId).Consistency(gocql.One).Scan(&deleted)

    // if err != nil || deleted {
    //     RespondError(w, ErrUserNotExist, http.StatusNotFound)
    //     return
    // }

    // success
    RespondTrue(w)
    return
}

/*
 * XMPP CheckPassword request structure
 */
type CheckPasswordParams struct {
    UserId int64  `param:"user" validate:"required"`
    Server string `param:"server" validate:"required"`
    Token  string `param:"pass" validate:"required"`
}

func (h *Handler) CheckPassword(w http.ResponseWriter, req *http.Request) {

    var p CheckPasswordParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    if p.Server != kImDomain {
        RespondError(w, ErrIMServerInvalid, http.StatusBadRequest)
        return
    }

    id, _, err := ExtractToken(p.Token)
    if err != nil || p.UserId != id {
        RespondError(w, ErrTokenInvalid, http.StatusUnauthorized)
        return
    }

    // success
    RespondTrue(w)
    return
}
