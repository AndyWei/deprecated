/*
 * auth.go
 * auth related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package user

import (
    "encoding/json"
    "errors"
    "github.com/dgrijalva/jwt-go"
    "github.com/gocql/gocql"
    "github.com/julienschmidt/httprouter"
    "github.com/spf13/viper"
    "golang.org/x/crypto/bcrypt"
    . "joyyapp.com/wink/util"
    "net/http"
    "strconv"
    "time"
)

var kBcryptCost int = 0
var kImDomain string = ""
var kJwtKey []byte = nil
var kJwtPeriodInMinutes int = 0

func init() {

    viper.SetConfigName("config")
    viper.SetConfigType("toml")
    viper.AddConfigPath("/etc/wink/")
    err := viper.ReadInConfig()
    PanicOnError(err)

    kBcryptCost = viper.GetInt("bcrypt.cost")

    kImDomain = viper.GetString("im.domain")

    key := viper.GetString("jwt.key")
    kJwtKey = []byte(key)
    kJwtPeriodInMinutes = viper.GetInt("jwt.period_in_minutes")
}

/*
 * JWT auth middleware
 */

// func JwtAuthMiddleWare() gin.HandlerFunc {

//     return func(c *gin.Context) {
//         parsedToken, err := jwt.ParseFromRequest(c.Request, func(token *jwt.Token) (interface{}, error) {
//             return kJwtKey, nil
//         })

//         if err != nil || !parsedToken.Valid {
//             c.AbortWithStatus(http.StatusUnauthorized)
//             return
//         }

//         id, username, err := extractParsedToken(parsedToken)
//         if err != nil || id == 0 {
//             c.AbortWithStatus(http.StatusUnauthorized)
//             return
//         }

//         c.Set("userid", id)
//         c.Set("username", username)
//         c.Next()
//     }
// }

type AuthReplyBody struct {
    Id    int64  `json:"id"`
    Token string `json:"token"`
}

/*
 * Signup endpoint
 */
func (h *Handler) SignUp(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {

    r.ParseForm()
    username := r.Form.Get("username")
    password := r.Form.Get("password")

    if len(username) < 2 || len(password) < 2 {
        ReplyError(w, ErrUsernameTooShort, http.StatusBadRequest)
        return
    }

    // generate userid
    userid := NewID()

    // encrypt password
    epassword, err := bcrypt.GenerateFromPassword([]byte(password), kBcryptCost)

    // write DB. note lightweight transaction is used to make sure the username is unique
    applied, err := h.DB.Query(`INSERT INTO user_by_name (username, id, password) VALUES (?, ?, ?) IF NOT EXISTS`,
        username, userid, epassword).ScanCAS()
    if err != nil || !applied {
        ReplyError(w, ErrUsernameConflict, http.StatusBadRequest)
        return
    }

    if err := h.DB.Query(`INSERT INTO user (id, username, deleted) VALUES (?, ?, false)`,
        userid, username).Exec(); err != nil {
        LogError(err)
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    // create JWT token
    token, err := newJwtToken(username, userid)
    if err != nil {
        LogError(err)
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    // success
    LogInfof("New user signed up. userid = %v, username = %v\n\r", userid, username)

    rb := &AuthReplyBody{Id: userid, Token: token}
    body, _ := json.Marshal(rb)
    ReplySuccess(w, body)
}

/*
 * Signin endpoint
 */

func (h *Handler) SignIn(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {

    r.ParseForm()
    username := r.Form.Get("username")
    password := r.Form.Get("password")

    if len(username) < 2 || len(password) < 2 {
        ReplyError(w, ErrUsernameTooShort, http.StatusBadRequest)
        return
    }

    // read encrypted password from DB
    var userid int64
    var epassword string
    if err := h.DB.Query(`SELECT id, password FROM user_by_name WHERE username = ? LIMIT 1`,
        username).Consistency(gocql.One).Scan(&userid, &epassword); err != nil {

        LogError(err)
        ReplyError(w, ErrUserNotExist, http.StatusBadRequest)
        return
    }

    // check password
    if err := bcrypt.CompareHashAndPassword([]byte(epassword), []byte(password)); err != nil {
        ReplyError(w, ErrPasswordInvalid, http.StatusUnauthorized)
        return
    }

    // success
    token, err := newJwtToken(username, userid)
    LogError(err)

    rb := &AuthReplyBody{Id: userid, Token: token}
    body, _ := json.Marshal(rb)
    ReplySuccess(w, body)
    return
}

/*
 * XMPP check user existence endpoint
 */
func (h *Handler) CheckExistence(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {

    r.ParseForm()
    idstr := r.Form.Get("user")
    server := r.Form.Get("server")

    if server != kImDomain {
        ReplyError(w, ErrIMServerInvalid, http.StatusConflict)
        return
    }

    userid, err := strconv.ParseInt(idstr, 10, 64)
    if err != nil {
        LogError(err)
        ReplyError(w, ErrUserNotExist, http.StatusNotFound)
        return
    }

    // read DB
    var deleted bool
    err = h.DB.Query(`SELECT deleted FROM user WHERE id = ? LIMIT 1`,
        userid).Consistency(gocql.One).Scan(&deleted)

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
 * XMPP check password endpoint
 */
func (h *Handler) CheckPassword(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {

    r.ParseForm()
    idstr := r.Form.Get("user")
    server := r.Form.Get("server")
    token := r.Form.Get("pass")

    if server != kImDomain {
        ReplyError(w, ErrIMServerInvalid, http.StatusConflict)
        return
    }

    userid, err := strconv.ParseInt(idstr, 10, 64)
    if err != nil {
        LogError(err)
        ReplyError(w, ErrUserNotExist, http.StatusNotFound)
        return
    }

    idInToken, _, err := extractJwtToken(token)
    LogError(err)

    if err != nil || userid != idInToken {
        ReplyError(w, ErrTokenInvalid, http.StatusUnauthorized)
        return
    }

    // success
    ReplyTrue(w)
    return
}

func newJwtToken(username string, id int64) (string, error) {

    token := jwt.New(jwt.SigningMethodHS256) // SigningMethodHS256 is a var of type *SigningMethodHMAC
    idString := strconv.FormatInt(id, 10)
    token.Claims["id"] = idString
    token.Claims["username"] = username
    token.Claims["exp"] = time.Now().Add(time.Duration(kJwtPeriodInMinutes) * time.Minute).Unix()
    signedString, err := token.SignedString(kJwtKey)
    LogError(err)

    return signedString, err
}

func extractParsedToken(parsedToken *jwt.Token) (int64, string, error) {

    if !parsedToken.Valid {
        return 0, "", errors.New(ErrTokenInvalid)
    }

    idString, ok := parsedToken.Claims["id"].(string)
    if !ok {
        return 0, "", errors.New(ErrTokenInvalid)
    }

    id, err := strconv.ParseInt(idString, 10, 64)
    if err != nil {
        return 0, "", errors.New(ErrTokenInvalid)
    }

    username, ok := parsedToken.Claims["username"].(string)
    if !ok {
        return 0, "", errors.New(ErrTokenInvalid)
    }

    // finally we got a good one
    return id, username, nil
}

func extractJwtToken(tokenString string) (int64, string, error) {

    parsedToken, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
        // must check alg field to confirm the encrypting method, otherwise JWT is not safe
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, errors.New(ErrTokenInvalidAlg)
        }
        return kJwtKey, nil
    })

    if err != nil {
        return 0, "", err
    }

    return extractParsedToken(parsedToken)
}
