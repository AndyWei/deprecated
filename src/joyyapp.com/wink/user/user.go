/*
 * user.go
 * user related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package user

import (
    "github.com/gin-gonic/gin"
    "joyyapp.com/wink/cassandra"
    . "joyyapp.com/wink/util"
    "net/http"
    "strconv"
)

/*
 * Profile endpoints
 */
type ProfileJson struct {
    Phone  string `json:"phone" binding:"required"`
    Avatar string `json:"avatar" binding:"required"`
    Sex    string `json:"sex" binding:"required"`
    Yob    int    `json:"yob" binding:"required"`
    Bio    string `json:"bio"`
}

func SetProfile(c *gin.Context) {

    userid, _ := c.Keys["userid"].(int64)
    username, _ := c.Keys["username"].(string)
    db := cassandra.SharedSession()

    var json ProfileJson
    err := c.BindJSON(&json)
    LogError(err)

    if err := db.Query(`UPDATE user SET phone = ?, avatar = ?, sex = ?, yob = ?, bio = ? WHERE id = ?`,
        json.Phone, json.Avatar, json.Sex, json.Yob, json.Bio, userid).Exec(); err != nil {
        LogFatal(err)
        c.AbortWithError(http.StatusBadGateway, err)
        return
    }

    if err := db.Query(`INSERT INTO user_by_phone (phone, username, id) VALUES (?, ?, ?)`,
        json.Phone, username, userid).Exec(); err != nil {
        LogFatal(err)
        c.AbortWithError(http.StatusBadGateway, err)
        return
    }

    idString := strconv.FormatInt(userid, 10)

    c.String(http.StatusOK, idString)
    return
}

func GetProfile(c *gin.Context) {

}
