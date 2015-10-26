/*
 * auth.go
 * auth related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package auth

import (
    "errors"
    jwt_lib "github.com/dgrijalva/jwt-go"
    "github.com/spf13/viper"
    . "joyyapp.com/wink/util"
    "net/http"
    "strconv"
    "time"
)

var (
    kJwtKey             []byte = nil
    kJwtPeriodInMinutes int    = 0
)

func init() {

    viper.SetConfigName("config")
    viper.SetConfigType("toml")
    viper.AddConfigPath("/etc/wink/")
    err := viper.ReadInConfig()
    LogPanic(err)

    key := viper.GetString("jwt.key")
    kJwtKey = []byte(key)
    kJwtPeriodInMinutes = viper.GetInt("jwt.period_in_minutes")
}

/*
 * JWT auth middleware
 */
func JWTMiddleware(next HandlerFunc) http.HandlerFunc {

    return func(w http.ResponseWriter, req *http.Request) {

        parsedToken, err := jwt_lib.ParseFromRequest(req, keyFunc)

        if err != nil {
            ReplyError(w, err.Error(), http.StatusUnauthorized)
            return
        }

        if !parsedToken.Valid {
            ReplyError(w, ErrTokenInvalid, http.StatusUnauthorized)
            return
        }

        idstr, username, err := extractParsedToken(parsedToken)
        if err != nil {
            ReplyError(w, err.Error(), http.StatusUnauthorized)
            return
        }

        userid, err := strconv.ParseInt(idstr, 10, 64)
        if err != nil {
            ReplyError(w, err.Error(), http.StatusUnauthorized)
            return
        }

        next(w, req, userid, username)
    }
}

func NewToken(userid int64, username string) (signedToken string, err error) {

    token := jwt_lib.New(jwt_lib.SigningMethodHS256) // SigningMethodHS256 is a var of type *SigningMethodHMAC
    idstr := strconv.FormatInt(userid, 10)
    token.Claims["id"] = idstr
    token.Claims["username"] = username
    token.Claims["exp"] = time.Now().Add(time.Duration(kJwtPeriodInMinutes) * time.Minute).Unix()
    signedToken, err = token.SignedString(kJwtKey)

    return signedToken, err
}

func ExtractToken(tokenString string) (userid int64, username string, err error) {

    parsedToken, err := jwt_lib.Parse(tokenString, keyFunc)

    if err != nil {
        return 0, "", err
    }

    idstr, username, err := extractParsedToken(parsedToken)
    if err != nil {
        return 0, "", err
    }

    userid, err = strconv.ParseInt(idstr, 10, 64)
    if err != nil {
        return 0, "", err
    }

    return userid, username, err
}

func keyFunc(token *jwt_lib.Token) (interface{}, error) {

    // must check alg field to confirm the encrypting method, otherwise JWT is not safe
    if _, ok := token.Method.(*jwt_lib.SigningMethodHMAC); !ok {
        return nil, errors.New(ErrTokenInvalidAlg)
    }
    return kJwtKey, nil
}

func extractParsedToken(parsedToken *jwt_lib.Token) (idstr, username string, err error) {

    if !parsedToken.Valid {
        return "", "", errors.New(ErrTokenInvalid)
    }

    idstr, ok := parsedToken.Claims["id"].(string)
    if !ok {
        return "", "", errors.New(ErrTokenInvalid)
    }

    username, ok = parsedToken.Claims["username"].(string)
    if !ok {
        return "", "", errors.New(ErrTokenInvalid)
    }

    // finally we got a good one
    return idstr, username, nil
}
