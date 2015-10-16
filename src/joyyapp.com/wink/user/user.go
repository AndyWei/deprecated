/*
 * user.go
 * user related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package user

import (
    "github.com/gin-gonic/gin"
    . "github.com/spf13/viper"
    "golang.org/x/crypto/bcrypt"
    "joyyapp.com/wink/cassandra"
    . "joyyapp.com/wink/util"
)

var bcryptCost int = 0

func init() {

    SetConfigName("config")
    SetConfigType("toml")
    AddConfigPath("/etc/wink/")
    err := ReadInConfig()
    PanicOnError(err)

    bcryptCost = GetInt("bcrypt.cost")
}

type SignupJson struct {
    Username string `json:"username" binding:"required"`
    Password string `json:"password" binding:"required"`
    Phone    int64  `json:"phone" binding:"required"`
}

func Signup(c *gin.Context) {

    db := cassandra.SharedSession()

    var json SignupJson
    err := c.BindJSON(&json)
    LogError(err)

    // generate id
    id := NewID()
    LogInfo("New user signup start. id = %d", id)

    // encrypt password
    encryptedPassword, err := bcrypt.GenerateFromPassword([]byte(json.Password), bcryptCost)

    err = db.Query(`INSERT INTO user_by_name (name, password, id, phone) VALUES (?, ?, ?, ?)`, json.Username, encryptedPassword, id, json.Phone).Exec()
    LogFatal(err)

    c.JSON(200, gin.H{"status": "signup success"})
}
