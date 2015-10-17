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
    "time"
)

var bcryptCost int = 0
var jwtKey []byte = nil
var jwtPeriodInMinutes int = 0

func init() {

    SetConfigName("config")
    SetConfigType("toml")
    AddConfigPath("/etc/wink/")
    err := ReadInConfig()
    PanicOnError(err)

    bcryptCost = GetInt("bcrypt.cost")

    key := GetString("jwt.key")
    jwtKey = []byte(key)
    jwtPeriodInMinutes = GetInt("jwt.period_in_minutes")
}

func jwtToken(username string, id int64) (error, string) {

    token := jwt.New(jwt.SigningMethodHS256)
    token.Claims["id"] = id
    token.Claims["username"] = username
    token.Claims["exp"] = time.Now().Add(time.Duration(jwtPeriodInMinutes) * time.Minute).Unix()
    signedString, err := token.SignedString(jwtKey)
    LogFatal(err)

    return err, signedString
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
    encryptedPassword, err := bcrypt.GenerateFromPassword([]byte(json.Password), bcryptCost)

    // write db. note lightweight transaction is used to make sure the username is unique
    applied, err := db.Query(`INSERT INTO user_by_name (username, deleted, id, password) VALUES (?, false, ?, ?) IF NOT EXISTS`,
        json.Username, id, encryptedPassword).ScanCAS()
    LogError(err)
    if !applied {
        LogInfof("username already exist. username = %s", json.Username)
        c.JSON(http.StatusBadRequest, gin.H{"error": "user already exist"})
        return
    }

    err = db.Query(`INSERT INTO user (id, username, deleted, n_follower, n_following) VALUES (?, ?, false, 0, 0)`,
        id, json.Username).Exec()
    LogFatal(err)

    // create JWT token
    token, _ := jwtToken(json.Username, id)

    c.JSON(http.StatusOK, gin.H{"id": id, "token": token})
}

func Signin(c *gin.Context) {

    db := cassandra.SharedSession()

    var json CredentialJson
    err := c.BindJSON(&json)
    LogError(err)

    // read db
    var id int64
    var encryptedPassword string
    err = db.Query(`SELECT id, password FROM user_by_name WHERE username = ? AND deleted = false LIMIT 1`,
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
    token, _ := jwtToken(json.Username, id)

    c.JSON(http.StatusOK, gin.H{"id": id, "token": token})
}
