/*
 * cassandra.go
 * The collection of utility functions
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package util

import (
    "fmt"
    "joyyapp.com/wink/idgen"
    "log"
    "net/http"
    "runtime"
)

type DefaultPostResponse struct {
    Error int `json:"error"`
}

const (
    ErrIMServerInvalid  = "im server is invalid"
    ErrPasswordInvalid  = "password is invalid"
    ErrTokenInvalid     = "token is invalid"
    ErrTokenInvalidAlg  = "token encoding algorithm is invalid"
    ErrUsernameConflict = "username or password is too short"
    ErrUsernameTooShort = "username or password is too short"
    ErrUserNotExist     = "user does not exist"
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

func ReplyError(w http.ResponseWriter, err string, code int) {

    w.Header().Set("Content-Type", "application/json; charset=utf-8")
    w.WriteHeader(code)
    fmt.Fprintf(w, "{error: %v}\r\n", err)
}

func ReplySuccess(w http.ResponseWriter, body []byte) {

    w.Header().Set("Content-Type", "application/json; charset=utf-8")
    w.WriteHeader(http.StatusOK)
    w.Write(body)
}

func ReplyTrue(w http.ResponseWriter) {

    w.WriteHeader(http.StatusOK)
    w.Write([]byte("true"))
}
