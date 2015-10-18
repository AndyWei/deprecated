/*
 * user.go
 * user related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package user

import (
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

    token := jwt.New(jwt.SigningMethodHS256)
    token.Claims["id"] = id
    token.Claims["username"] = username
    token.Claims["exp"] = time.Now().Add(time.Duration(kJwtPeriodInMinutes) * time.Minute).Unix()
    signedString, err := token.SignedString(kJwtKey)
    LogFatal(err)

    return signedString, err
}

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
    LogInfof("New user signup start. id = %d", id)

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

type XmppCredentialForm struct {
    Userid int64  `form:"user" binding:"required"`
    Server string `form:"server" binding:"required"`
    Token  string `form:"pass" binding:"required"`
}

func VerifyToken(c *gin.Context) {

}
