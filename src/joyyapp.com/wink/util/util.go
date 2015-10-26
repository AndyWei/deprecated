/*
 * util.go
 * The collection of utility functions
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package util

import (
    "fmt"
    "github.com/goji/param"
    "gopkg.in/go-playground/validator.v8"
    "log"
    "net/http"
    "runtime"
)

type HandlerFunc func(http.ResponseWriter, *http.Request, int64, string)

const (
    ErrIMServerInvalid  = "im server is invalid"
    ErrPasswordInvalid  = "password is invalid"
    ErrPasswordTooShort = "password is too short"
    ErrRegionInvalid    = "region is invalid"
    ErrResponseInvalid  = "response is invalid"
    ErrSexInvalid       = "sex is invalid"
    ErrTokenInvalid     = "token is invalid"
    ErrTokenInvalidAlg  = "token encoding algorithm is invalid"
    ErrUsernameConflict = "username has been taken"
    ErrUsernameTooShort = "username is too short"
    ErrUserNotExist     = "user does not exist"
    ErrYobInvalid       = "yob is invalid"
)

var validate *validator.Validate

func init() {
    config := &validator.Config{TagName: "validate"}
    validate = validator.New(config)
}

/*
 * Log
 */
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

func LogInfo(v ...interface{}) {
    log.Println(v...)
}

func LogInfof(format string, v ...interface{}) {
    log.Printf(format, v...)
}

func LogPanic(err error) {
    if err != nil {
        _, fn, line, _ := runtime.Caller(1)
        log.Panicf("[ERROR] %s:%d %v", fn, line, err)
    }
}

/*
 * reply
 */
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
    w.WriteHeader(http.StatusOK)
}

func ReplyTrue(w http.ResponseWriter) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("true"))
}

/*
 * request
 */
func ParseAndCheck(req *http.Request, target interface{}) (err error) {

    req.ParseForm()
    if err = param.Parse(req.Form, target); err != nil {
        LogError(err)
        return err
    }

    // LogInfof("struct = %v", target)
    errs := validate.Struct(target)
    if errs != nil {
        err = errs.(validator.ValidationErrors)
        LogError(err)
        return err
    }

    return nil
}
