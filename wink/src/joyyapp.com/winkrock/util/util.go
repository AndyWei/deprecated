/*
 * util.go
 * The collection of utility functions
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package util

import (
    "encoding/json"
    "fmt"
    "github.com/goji/param"
    "gopkg.in/go-playground/validator.v8"
    "log"
    "net/http"
    "runtime"
    "time"
)

type HandlerFunc func(http.ResponseWriter, *http.Request, int64, string)

const (
    ErrIMServerInvalid  = "1000: im server is invalid"
    ErrPasswordInvalid  = "1010: password is invalid"
    ErrPasswordTooShort = "1020: password is too short"
    ErrPnsInvalid       = "1030: push notification service is invalid"
    ErrTokenInvalid     = "1040: token is invalid"
    ErrTokenInvalidAlg  = "1050: token encoding algorithm is invalid"
    ErrUsernameConflict = "1060: username has been taken"
    ErrUsernameTooShort = "1070: username is too short"
    ErrUserNotExist     = "1080: user does not exist"
    ErrSmsCodeInvalid   = "1090: sms code is invalid"
)

const (
    epoch = int64(1420070400000) // 01 Jan 2015 00:00:00 GMT
)

var validate *validator.Validate

func init() {
    config := &validator.Config{TagName: "validate"}
    validate = validator.New(config)
}

/*
 * Time
 */
func Epoch() int64 {
    return epoch
}

func TimeInMillis() int64 {
    return int64(time.Nanosecond) * time.Now().UTC().UnixNano() / int64(time.Millisecond)
}

func Millis() int64 {
    timestamp := TimeInMillis()
    return timestamp - epoch
}

// All the years start from year 2000. E.g., 2015 -> 15
// return value is in form of yymmddhh
func Hour(t time.Time) int {
    year := t.Year() - 2000
    month := int(t.Month())
    return (year * 1000000) + (month * 10000) + (t.Day() * 100) + t.Hour()
}

// return value is in form of yymmdd
func Day(t time.Time) int {
    year := t.Year() - 2000
    month := int(t.Month())
    return (year * 10000) + (month * 100) + t.Day()
}

// return value is in form of yymm
func Month(t time.Time) int {
    year := t.Year() - 2000
    month := int(t.Month())
    return (year * 100) + month
}

// return value is in form of yy
func Year(t time.Time) int {
    return t.Year() - 2000
}

// return value is in form of yymmddhh
func ThisHour() int {
    return Hour(time.Now().UTC())
}

// return value is in form of yymmdd
func ThisDay() int {
    return Day(time.Now().UTC())
}

// return value is in form of yymm
func ThisMonth() int {
    return Month(time.Now().UTC())
}

// return value is in form of yy
func ThisYear() int {
    return Year(time.Now().UTC())
}

// return value is in form of yymmddhh
func NextHour() int {
    now := time.Now().UTC()
    t := now.Add(time.Duration(1) * time.Hour)
    return Hour(t)
}

// return value is in form of yymmddhh
func NextMonth() int {
    now := time.Now().UTC()
    month := int(now.Month())
    if month == 12 {
        year := now.Year() - 2000
        return (year+1)*100 + 1
    }
    return ThisMonth() + 1
}

func IsLastDayOfThisMonth() bool {
    today := time.Now().UTC()
    tomorrow := today.Add(time.Duration(24) * time.Hour)
    return Month(today) != Month(tomorrow)
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

func LogOutsideError(err string) {
    if len(err) > 0 {
        _, fn, line, _ := runtime.Caller(2)
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
func RespondData(w http.ResponseWriter, bytes []byte) {
    w.Header().Set("Content-Type", "application/json; charset=utf-8")
    w.WriteHeader(http.StatusOK)
    w.Write(bytes)
}

func RespondError(w http.ResponseWriter, err interface{}, code int) {
    var msg string
    switch v := err.(type) {
    case error:
        msg = v.Error()
    default:
        msg = v.(string)
    }
    LogOutsideError(msg)
    w.Header().Set("Content-Type", "application/json; charset=utf-8")
    w.WriteHeader(code)
    fmt.Fprintf(w, "{error: %v}\r\n", msg)
}

func RespondKV(w http.ResponseWriter, key string, value interface{}) {
    w.Header().Set("Content-Type", "application/json; charset=utf-8")
    w.WriteHeader(http.StatusOK)

    m := map[string]interface{}{
        key: value,
    }

    bytes, _ := json.Marshal(m)
    w.Write(bytes)
}

func RespondOK(w http.ResponseWriter) {
    w.WriteHeader(http.StatusOK)
}

func RespondTrue(w http.ResponseWriter) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("true"))
}

/*
 * request
 */
func ParseAndCheck(req *http.Request, target interface{}) (err error) {

    req.ParseForm()
    if err = param.Parse(req.Form, target); err != nil {
        return err
    }

    // LogInfof("struct = %v", target)
    errs := validate.Struct(target)
    if errs != nil {
        err = errs.(validator.ValidationErrors)
        return err
    }

    return nil
}
