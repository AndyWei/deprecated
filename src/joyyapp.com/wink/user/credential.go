/*
 * user.go
 * user related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package user

import (
    "fmt"
    "github.com/dgrijalva/jwt-go"
    "github.com/gin-gonic/gin"
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

func jwtToken(username string, id int64) (string, error) {

    token := jwt.New(jwt.SigningMethodHS256) // SigningMethodHS256 is a var of type *SigningMethodHMAC
    idString := strconv.FormatInt(id, 10)
    token.Claims["id"] = idString
    token.Claims["username"] = username
    token.Claims["exp"] = time.Now().Add(time.Duration(kJwtPeriodInMinutes) * time.Minute).Unix()
    signedString, err := token.SignedString(kJwtKey)
    LogFatal(err)

    return signedString, err
}

func DecodeJwtToken(tokenString string) (int64, string, error) {

    decoded, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
        // must check alg field to confirm the encrypting method, otherwise JWT is not safe
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, fmt.Errorf("Unexpected signing method: %v", token.Header["alg"])
        }
        return kJwtKey, nil
    })

    if err != nil || !decoded.Valid {
        return 0, "", err
    }

    idString, ok := decoded.Claims["id"].(string)
    if !ok {
        return 0, "", fmt.Errorf("Invalid id inside token claims")
    }

    id, err := strconv.ParseInt(idString, 10, 64)
    if err != nil {
        return 0, "", fmt.Errorf("Invalid id inside token claims")
    }

    username, ok := decoded.Claims["username"].(string)
    if !ok {
        return 0, "", fmt.Errorf("Invalid username inside token claims")
    }

    // finally we got a good one
    return id, username, nil
}

/*
 * Signup endpoint
 */
type CredentialJson struct {
    Username string `json:"username" binding:"required"`
    Password string `json:"password" binding:"required"`
}

func Signup(c *gin.Context) {
    db := cassandra.SharedSession()

    var json CredentialJson
    err := c.BindJSON(&json)
    LogError(err)

    // generate userid
    id := NewID()
    LogInfof("New user signup. userid = %v", id)

    // encrypt password
    encryptedPassword, err := bcrypt.GenerateFromPassword([]byte(json.Password), kBcryptCost)

    // write db. note lightweight transaction is used to make sure the username is unique
    applied, err := db.Query(`INSERT INTO user_by_name (username, id, password) VALUES (?, ?, ?) IF NOT EXISTS`,
        json.Username, id, encryptedPassword).ScanCAS()
    LogError(err)

    if !applied {
        LogInfof("username already exist. username = %s", json.Username)
        c.JSON(http.StatusBadRequest, gin.H{"error": "user already exist"})
        return
    }

    err = db.Query(`INSERT INTO user (id, username, deleted, n_friend) VALUES (?, ?, false, 0)`,
        id, json.Username).Exec()
    LogFatal(err)

    // create JWT token
    token, err := jwtToken(json.Username, id)
    LogError(err)

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
    db := cassandra.SharedSession()

    var json CredentialJson
    err := c.BindJSON(&json)
    LogError(err)

    // read db
    var id int64
    var encryptedPassword string
    err = db.Query(`SELECT id, password FROM user_by_name WHERE username = ? LIMIT 1`,
        json.Username).Scan(&id, &encryptedPassword)
    LogError(err)

    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "user does not exist"})
        return
    }

    // check password
    err = bcrypt.CompareHashAndPassword([]byte(encryptedPassword), []byte(json.Password))
    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "incorrect password"})
        return
    }

    // create JWT token
    token, err := jwtToken(json.Username, id)
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

    db := cassandra.SharedSession()

    var form XmppUserForm
    err := c.Bind(&form)
    LogError(err)

    // check server
    if form.Server != kImDomain {
        c.String(http.StatusConflict, "incorrect im server")
        return
    }

    id, err := strconv.ParseInt(form.Userid, 10, 64)
    LogError(err)
    if err != nil {
        c.String(http.StatusNotFound, "user does not exist")
        return
    }

    // read db
    var deleted bool
    err = db.Query(`SELECT deleted FROM user WHERE id = ? LIMIT 1`,
        id).Scan(&deleted)
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

    LogError(err)
    if err != nil {
        c.String(http.StatusNotFound, "user does not exist")
        return
    }

    idInToken, _, err := DecodeJwtToken(form.Token)
    LogError(err)

    if err != nil || id != idInToken {
        c.String(http.StatusUnauthorized, "the token is not valid or not matched")
        return
    }

    c.String(http.StatusOK, "true")
    return
}
