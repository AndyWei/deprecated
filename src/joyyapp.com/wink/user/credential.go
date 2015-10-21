/*
 * credential.go
 * credential related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package user

import (
    "fmt"
    "github.com/dgrijalva/jwt-go"
    "github.com/gin-gonic/gin"
    "github.com/gocql/gocql"
    . "github.com/spf13/viper"
    "golang.org/x/crypto/bcrypt"
    "joyyapp.com/wink/cassandra"
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

    SetConfigName("config")
    SetConfigType("toml")
    AddConfigPath("/etc/wink/")
    err := ReadInConfig()
    PanicOnError(err)

    kBcryptCost = GetInt("bcrypt.cost")

    kImDomain = GetString("im.domain")

    key := GetString("jwt.key")
    kJwtKey = []byte(key)
    kJwtPeriodInMinutes = GetInt("jwt.period_in_minutes")
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

    err := fmt.Errorf("Invalid token")
    if !parsedToken.Valid {
        return 0, "", err
    }

    idString, ok := parsedToken.Claims["id"].(string)
    if !ok {
        return 0, "", fmt.Errorf("Invalid id inside token claims")
    }

    id, err := strconv.ParseInt(idString, 10, 64)
    if err != nil {
        return 0, "", fmt.Errorf("Invalid id inside token claims")
    }

    username, ok := parsedToken.Claims["username"].(string)
    if !ok {
        return 0, "", fmt.Errorf("Invalid username inside token claims")
    }

    // finally we got a good one
    return id, username, nil
}

func extractJwtToken(tokenString string) (int64, string, error) {

    parsedToken, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
        // must check alg field to confirm the encrypting method, otherwise JWT is not safe
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, fmt.Errorf("Unexpected signing method: %v", token.Header["alg"])
        }
        return kJwtKey, nil
    })

    if err != nil {
        return 0, "", err
    }

    return extractParsedToken(parsedToken)
}

/*
 * JWT auth middleware
 */

func JwtAuthMiddleWare() gin.HandlerFunc {

    return func(c *gin.Context) {
        parsedToken, err := jwt.ParseFromRequest(c.Request, func(token *jwt.Token) (interface{}, error) {
            return kJwtKey, nil
        })

        if err != nil || !parsedToken.Valid {
            c.AbortWithStatus(http.StatusUnauthorized)
            return
        }

        id, username, err := extractParsedToken(parsedToken)
        if err != nil || id == 0 {
            c.AbortWithStatus(http.StatusUnauthorized)
            return
        }

        c.Set("userid", id)
        c.Set("username", username)
        c.Next()
    }
}

/*
 * Signup endpoint
 */
type CredentialParams struct {
    Username string `json:"username" binding:"required"`
    Password string `json:"password" binding:"required"`
}

func Signup(c *gin.Context) {
    session := cassandra.SharedSession()

    var json CredentialParams
    err := c.BindJSON(&json)
    LogError(err)

    // generate userid
    id := NewID()

    // encrypt password
    encryptedPassword, err := bcrypt.GenerateFromPassword([]byte(json.Password), kBcryptCost)

    // write DB. note lightweight transaction is used to make sure the username is unique
    applied, err := session.Query(`INSERT INTO user_by_name (username, id, password) VALUES (?, ?, ?) IF NOT EXISTS`,
        json.Username, id, encryptedPassword).ScanCAS()
    if err != nil || !applied {
        LogError(err)
        c.AbortWithError(http.StatusBadRequest, err)
        return
    }

    if err := session.Query(`INSERT INTO user (id, username, deleted) VALUES (?, ?, false)`,
        id, json.Username).Exec(); err != nil {
        LogError(err)
        c.AbortWithError(http.StatusBadGateway, err)
        return
    }

    // create JWT token
    token, err := newJwtToken(json.Username, id)
    LogError(err)

    LogInfof("New user signedup. userid = %v", id)

    idString := strconv.FormatInt(id, 10)
    c.JSON(http.StatusOK, gin.H{
        "id":    idString,
        "token": token,
    })
    return
}

/*
 * Signin endpoint
 */

func Signin(c *gin.Context) {
    session := cassandra.SharedSession()

    var json CredentialParams
    err := c.BindJSON(&json)
    LogError(err)

    // read encrypted password from DB
    var id int64
    var encryptedPassword string
    if err := session.Query(`SELECT id, password FROM user_by_name WHERE username = ? LIMIT 1`,
        json.Username).Consistency(gocql.One).Scan(&id, &encryptedPassword); err != nil {
        LogError(err)
        c.JSON(http.StatusUnauthorized, gin.H{"error": "user does not exist"})
        return
    }

    // check password
    if err := bcrypt.CompareHashAndPassword([]byte(encryptedPassword), []byte(json.Password)); err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "incorrect password"})
        return
    }

    // create JWT token
    token, err := newJwtToken(json.Username, id)
    LogError(err)

    idString := strconv.FormatInt(id, 10)
    c.JSON(http.StatusOK, gin.H{
        "id":    idString,
        "token": token,
    })
    return
}

/*
 * CheckExistence endpoint
 */

type XmppUserForm struct {
    Userid string `form:"user" binding:"required"`
    Server string `form:"server" binding:"required"`
}

func CheckExistence(c *gin.Context) {

    session := cassandra.SharedSession()

    var form XmppUserForm
    err := c.Bind(&form)
    LogError(err)

    // check server
    if form.Server != kImDomain {
        c.String(http.StatusConflict, "incorrect im server")
        return
    }

    id, err := strconv.ParseInt(form.Userid, 10, 64)
    if err != nil {
        LogError(err)
        c.String(http.StatusNotFound, "user does not exist")
        return
    }

    // read DB
    var deleted bool
    err = session.Query(`SELECT deleted FROM user WHERE id = ? LIMIT 1`,
        id).Consistency(gocql.One).Scan(&deleted)
    LogError(err)

    if err != nil || deleted {
        c.String(http.StatusNotFound, "user does not exist")
        return
    }

    c.String(http.StatusOK, "true")
    return
}

/*
 * VerifyToken endpoint
 */
type XmppCredentialForm struct {
    Userid string `form:"user" binding:"required"`
    Server string `form:"server" binding:"required"`
    Token  string `form:"pass" binding:"required"`
}

func VerifyToken(c *gin.Context) {

    var form XmppCredentialForm
    err := c.Bind(&form)
    LogError(err)

    // check server
    if form.Server != kImDomain {
        c.String(http.StatusConflict, "incorrect im server")
        return
    }

    id, err := strconv.ParseInt(form.Userid, 10, 64)
    if err != nil {
        LogError(err)
        c.String(http.StatusNotFound, "user does not exist")
        return
    }

    idInToken, _, err := extractJwtToken(form.Token)
    LogError(err)

    if err != nil || id != idInToken {
        c.String(http.StatusUnauthorized, "the token is not valid or not matched")
        return
    }

    c.String(http.StatusOK, "true")
    return
}
