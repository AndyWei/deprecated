/*
 * auth.go
 * auth related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package user

import (
    "encoding/json"
    "github.com/gocql/gocql"
    "github.com/julienschmidt/httprouter"
    . "github.com/mholt/binding"
    "github.com/spf13/viper"
    "golang.org/x/crypto/bcrypt"
    "joyyapp.com/wink/jwt"
    . "joyyapp.com/wink/util"
    "net/http"
)

var kBcryptCost int = 0
var kImDomain string = ""

func init() {

    viper.SetConfigName("config")
    viper.SetConfigType("toml")
    viper.AddConfigPath("/etc/wink/")
    err := viper.ReadInConfig()
    PanicOnError(err)

    kBcryptCost = viper.GetInt("bcrypt.cost")
    kImDomain = viper.GetString("im.domain")
}

/*
 * Signup/Signin request and reply structure
 */
type AuthRequest struct {
    Username string
    Password string
}

func (r *AuthRequest) FieldMap(req *http.Request) FieldMap {
    return FieldMap{
        &r.Username: Field{Form: "username", Required: true},
        &r.Password: Field{Form: "password", Required: true},
    }
}

func (r AuthRequest) Validate(req *http.Request, errs Errors) Errors {
    if len(r.Username) < 2 {
        errs.Add([]string{"username"}, "ComplaintError", ErrUsernameTooShort)
    }

    if len(r.Password) < 2 {
        errs.Add([]string{"password"}, "ComplaintError", ErrPasswordTooShort)
    }
    return errs
}

type AuthReply struct {
    Id    int64  `json:"id"`
    Token string `json:"token"`
}

func (h *Handler) SignUp(w http.ResponseWriter, req *http.Request, _ httprouter.Params) {

    r := new(AuthRequest)
    if Bind(req, r).Handle(w) {
        return
    }

    userid := NewID()
    epassword, err := bcrypt.GenerateFromPassword([]byte(r.Password), kBcryptCost)

    // write DB. note lightweight transaction is used to make sure the username is unique
    applied, err := h.DB.Query(`INSERT INTO user_by_name (username, id, password) VALUES (?, ?, ?) IF NOT EXISTS`,
        r.Username, userid, epassword).ScanCAS()
    if err != nil || !applied {
        ReplyError(w, ErrUsernameConflict, http.StatusBadRequest)
        return
    }

    if err := h.DB.Query(`INSERT INTO user (id, username, deleted) VALUES (?, ?, false)`,
        userid, r.Username).Exec(); err != nil {
        LogError(err)
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    // create JWT token
    token, err := jwt.NewToken(r.Username, userid)
    if err != nil {
        LogError(err)
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    // success
    LogInfof("New user signed up. userid = %v, username = %v\n\r", userid, r.Username)

    reply := &AuthReply{Id: userid, Token: token}
    body, _ := json.Marshal(reply)
    ReplyData(w, body)
    return
}

/*
 * Signin endpoint
 */

func (h *Handler) SignIn(w http.ResponseWriter, req *http.Request, _ httprouter.Params) {

    r := new(AuthRequest)
    if Bind(req, r).Handle(w) {
        return
    }

    // read encrypted password from DB
    var userid int64
    var epassword string
    if err := h.DB.Query(`SELECT id, password FROM user_by_name WHERE username = ? LIMIT 1`,
        r.Username).Consistency(gocql.One).Scan(&userid, &epassword); err != nil {

        LogError(err)
        ReplyError(w, ErrUserNotExist, http.StatusBadRequest)
        return
    }

    // check password
    if err := bcrypt.CompareHashAndPassword([]byte(epassword), []byte(r.Password)); err != nil {
        ReplyError(w, ErrPasswordInvalid, http.StatusUnauthorized)
        return
    }

    // success
    token, err := jwt.NewToken(r.Username, userid)
    if err != nil {
        LogError(err)
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    reply := &AuthReply{Id: userid, Token: token}
    body, _ := json.Marshal(reply)
    ReplyData(w, body)
    return
}

/*
 * XMPP CheckExistence request structure
 */
type CheckExistenceRequest struct {
    Userid int64
    Server string
}

func (r *CheckExistenceRequest) FieldMap(req *http.Request) FieldMap {
    return FieldMap{
        &r.Userid: Field{Form: "user", Required: true},
        &r.Server: Field{Form: "server", Required: true},
    }
}

func (r CheckExistenceRequest) Validate(req *http.Request, errs Errors) Errors {
    if r.Server != kImDomain {
        errs.Add([]string{"username"}, "ComplaintError", ErrIMServerInvalid)
    }
    return errs
}

func (h *Handler) CheckExistence(w http.ResponseWriter, req *http.Request, _ httprouter.Params) {

    r := new(CheckExistenceRequest)
    if Bind(req, r).Handle(w) {
        return
    }

    // read DB
    var deleted bool
    err := h.DB.Query(`SELECT deleted FROM user WHERE id = ? LIMIT 1`,
        r.Userid).Consistency(gocql.One).Scan(&deleted)

    if err != nil || deleted {
        LogError(err)
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
    Userid int64
    Server string
    Token  string
}

func (r *CheckPasswordRequest) FieldMap(req *http.Request) FieldMap {
    return FieldMap{
        &r.Userid: Field{Form: "user", Required: true},
        &r.Server: Field{Form: "server", Required: true},
        &r.Token:  Field{Form: "pass", Required: true},
    }
}

func (r CheckPasswordRequest) Validate(req *http.Request, errs Errors) Errors {
    if r.Server != kImDomain {
        errs.Add([]string{"username"}, "ComplaintError", ErrIMServerInvalid)
    }
    return errs
}

func (h *Handler) CheckPassword(w http.ResponseWriter, req *http.Request, _ httprouter.Params) {

    r := new(CheckPasswordRequest)
    if Bind(req, r).Handle(w) {
        return
    }

    id, _, err := jwt.ExtractToken(r.Token)
    LogError(err)

    if err != nil || r.Userid != id {
        ReplyError(w, ErrTokenInvalid, http.StatusUnauthorized)
        return
    }

    // success
    ReplyTrue(w)
    return
}
