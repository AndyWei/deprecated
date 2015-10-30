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
    "joyyapp.com/wink/idgen"
    . "joyyapp.com/wink/util"
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
    viper.AddConfigPath("/etc/wink/")
    err := viper.ReadInConfig()
    LogPanic(err)

    kBcryptCost = viper.GetInt("bcrypt.cost")
    kImDomain = viper.GetString("im.domain")
    kTokenTtl = viper.GetInt("jwt.tokenExpiresInMins") * 60
}

/*
 * Signup/Signin request and reply structure
 */
type AuthRequest struct {
    Username string `param:"username" validate:"min=2,max=40"`
    Password string `param:"password" validate:"min=2,max=40"`
}

type AuthReply struct {
    Id       int64  `json:"id"`
    Token    string `json:"token"`
    TokenTtl int    `json:"token_ttl"`
}

func (h *Handler) SignUp(w http.ResponseWriter, req *http.Request) {

    var r AuthRequest
    if err := ParseAndCheck(req, &r); err != nil {
        ReplyError(w, err.Error(), http.StatusBadRequest)
        return
    }

    epassword, err := bcrypt.GenerateFromPassword([]byte(r.Password), kBcryptCost)
    userid := idgen.NewID()

    // write DB. note lightweight transaction is used to make sure the username is unique
    applied, err := h.DB.Query(`INSERT INTO user_by_name (username, id, password) VALUES (?, ?, ?) IF NOT EXISTS`,
        r.Username, userid, epassword).ScanCAS()
    if err != nil || !applied {
        ReplyError(w, ErrUsernameConflict, http.StatusBadRequest)
        return
    }

    if err := h.DB.Query(`INSERT INTO user (id, username, deleted) VALUES (?, ?, false)`,
        userid, r.Username).Exec(); err != nil {
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    // create JWT token
    token, err := NewToken(userid, r.Username)
    if err != nil {
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    // success
    LogInfof("New user signed up. userid = %v, username = %v\n\r", userid, r.Username)

    reply := &AuthReply{Id: userid, Token: token, TokenTtl: kTokenTtl}
    body, _ := json.Marshal(reply)
    ReplyData(w, body)
    return
}

/*
 * Signin endpoint
 */

func (h *Handler) SignIn(w http.ResponseWriter, req *http.Request) {

    var r AuthRequest
    if err := ParseAndCheck(req, &r); err != nil {
        ReplyError(w, err.Error(), http.StatusBadRequest)
        return
    }

    // read encrypted password from DB
    var userid int64
    var epassword string
    if err := h.DB.Query(`SELECT id, password FROM user_by_name WHERE username = ? LIMIT 1`,
        r.Username).Consistency(gocql.One).Scan(&userid, &epassword); err != nil {
        ReplyError(w, ErrUserNotExist, http.StatusBadRequest)
        return
    }

    // check password
    if err := bcrypt.CompareHashAndPassword([]byte(epassword), []byte(r.Password)); err != nil {
        ReplyError(w, ErrPasswordInvalid, http.StatusUnauthorized)
        return
    }

    // success
    token, err := NewToken(userid, r.Username)
    if err != nil {
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    reply := &AuthReply{Id: userid, Token: token, TokenTtl: kTokenTtl}
    body, _ := json.Marshal(reply)
    ReplyData(w, body)
    return
}

/*
 * XMPP CheckExistence request structure
 */
type CheckExistenceRequest struct {
    Userid int64  `param:"user" validate:"required"`
    Server string `param:"server" validate:"required"`
}

func (h *Handler) CheckExistence(w http.ResponseWriter, req *http.Request) {

    var r CheckExistenceRequest
    if err := ParseAndCheck(req, &r); err != nil {
        ReplyError(w, err.Error(), http.StatusBadRequest)
        return
    }

    if r.Server != kImDomain {
        ReplyError(w, ErrIMServerInvalid, http.StatusBadRequest)
        return
    }

    // read DB
    var deleted bool
    err := h.DB.Query(`SELECT deleted FROM user WHERE id = ? LIMIT 1`,
        r.Userid).Consistency(gocql.One).Scan(&deleted)

    if err != nil || deleted {
        ReplyError(w, ErrUserNotExist, http.StatusNotFound)
        return
    }

    // success
    ReplyTrue(w)
    return
}

/*
 * XMPP CheckPassword request structure
 */
type CheckPasswordRequest struct {
    Userid int64  `param:"user" validate:"required"`
    Server string `param:"server" validate:"required"`
    Token  string `param:"pass" validate:"required"`
}

func (h *Handler) CheckPassword(w http.ResponseWriter, req *http.Request) {

    var r CheckPasswordRequest
    if err := ParseAndCheck(req, &r); err != nil {
        ReplyError(w, err.Error(), http.StatusBadRequest)
        return
    }

    if r.Server != kImDomain {
        ReplyError(w, ErrIMServerInvalid, http.StatusBadRequest)
        return
    }

    id, _, err := ExtractToken(r.Token)
    if err != nil || r.Userid != id {
        ReplyError(w, ErrTokenInvalid, http.StatusUnauthorized)
        return
    }

    // success
    ReplyTrue(w)
    return
}
