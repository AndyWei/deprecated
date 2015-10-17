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
    "log"
    "net/http"
    "time"
)

var bcryptCost int = 0
var jwtKey []byte = nil

func init() {

    SetConfigName("config")
    SetConfigType("toml")
    AddConfigPath("/etc/wink/")
    err := ReadInConfig()
    PanicOnError(err)

    bcryptCost = GetInt("bcrypt.cost")
    key := GetString("jwt.key")
    jwtKey = []byte(key)
    log.Print(jwtKey)
}

func jwtToken(name string, id int64) (error, string) {

    token := jwt.New(jwt.SigningMethodHS256)
    token.Claims["id"] = id
    token.Claims["name"] = name
    token.Claims["exp"] = time.Now().Add(time.Hour * 1).Unix()
    signedString, err := token.SignedString(jwtKey)
    LogFatal(err)

    return err, signedString
}

type CredentialJson struct {
    Name     string `json:"name" binding:"required"`
    Password string `json:"password" binding:"required"`
}

func Signup(c *gin.Context) {

    db := cassandra.SharedSession()

    var json CredentialJson
    err := c.BindJSON(&json)
    LogError(err)

    // generate userid
    id := NewID()
    LogInfo("New user signup start. id = %d", id)

    // encrypt password
    encryptedPassword, err := bcrypt.GenerateFromPassword([]byte(json.Password), bcryptCost)

    // write db
    err = db.Query(`INSERT INTO user_by_name (name, password, id) VALUES (?, ?, ?)`,
        json.Name, encryptedPassword, id).Exec()
    LogFatal(err)

    // create JWT token
    token, _ := jwtToken(json.Name, id)

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
    err = db.Query(`SELECT id, password FROM user_by_name WHERE name = ? LIMIT 1`,
        json.Name).Scan(&id, &encryptedPassword)
    LogFatal(err)

    // check password
    err = bcrypt.CompareHashAndPassword([]byte(encryptedPassword), []byte(json.Password))
    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "incorrect name or password"})
        return
    }

    // create JWT token
    token, _ := jwtToken(json.Name, id)

    c.JSON(http.StatusOK, gin.H{"id": id, "token": token})
}
