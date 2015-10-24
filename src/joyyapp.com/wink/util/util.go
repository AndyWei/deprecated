/*
 * cassandra.go
 * The collection of utility functions
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package util

import (
    "errors"
    "fmt"
    "github.com/julienschmidt/httprouter"
    "joyyapp.com/wink/idgen"
    "log"
    "net/http"
    "runtime"
    "strconv"
)

type DefaultPostResponse struct {
    Error int `json:"error"`
}

const (
    ErrIMServerInvalid  = "im server is invalid"
    ErrPasswordInvalid  = "password is invalid"
    ErrPasswordTooShort = "password is too short"
    ErrRegionInvalid    = "region is invalid"
    ErrSexInvalid       = "sex is invalid"
    ErrTokenInvalid     = "token is invalid"
    ErrTokenInvalidAlg  = "token encoding algorithm is invalid"
    ErrUsernameConflict = "username has been taken"
    ErrUsernameTooShort = "username is too short"
    ErrUserNotExist     = "user does not exist"
    ErrYobInvalid       = "yob is invalid"
)

func LogError(err error) {
    if err != nil {
        _, fn, line, _ := runtime.Caller(1)
        log.Printf("[error] %s:%d %v", fn, line, err)
    }
}

func LogFatal(err error) {
    if err != nil {
        _, fn, line, _ := runtime.Caller(1)
        log.Fatalf("[error] %s:%d %v", fn, line, err)
    }
}

func LogInfof(format string, v ...interface{}) {
    log.Printf(format, v...)
}

func PanicOnError(err error) {
    if err != nil {
        _, fn, line, _ := runtime.Caller(1)
        log.Panicf("[error] %s:%d %v", fn, line, err)
    }
}

func NewID() int64 {
    idGenerator := idgen.SharedInstance()
    err, id := idGenerator.NewId()
    PanicOnError(err)
    return id
}

func Parse(ps httprouter.Params) (userid int64, username string, err error) {
    idstr := ps.ByName("userid")
    userid, err = strconv.ParseInt(idstr, 10, 64)
    if err != nil {
        return 0, "", err
    }

    username = ps.ByName("username")
    if len(username) == 0 {
        return 0, "", errors.New(ErrTokenInvalid)
    }

    return userid, username, nil
}

func ReplyData(w http.ResponseWriter, body []byte) {
    w.Header().Set("Content-Type", "application/json; charset=utf-8")
    w.WriteHeader(http.StatusOK)
    w.Write(body)
}

func ReplyError(w http.ResponseWriter, err string, code int) {
    w.Header().Set("Content-Type", "application/json; charset=utf-8")
    w.WriteHeader(code)
    fmt.Fprintf(w, "{error: %v}\r\n", err)
}

func ReplyOK(w http.ResponseWriter) {
    w.Header().Set("Content-Type", "application/json; charset=utf-8")
    w.WriteHeader(http.StatusOK)
}

func ReplyTrue(w http.ResponseWriter) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("true"))
}
