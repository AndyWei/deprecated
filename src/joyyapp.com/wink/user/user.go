/*
 * user.go
 * user related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package user

import (
    "github.com/gin-gonic/gin"
    "joyyapp.com/wink/cache"
    "joyyapp.com/wink/cassandra"
    . "joyyapp.com/wink/util"
    "net/http"
)

/*
 * Profile endpoints
 */
type ProfileJson struct {
    Phone  int64  `json:"phone" binding:"required"`
    Avatar string `json:"avatar" binding:"required"`
    Sex    string `json:"sex" binding:"required"`
    Yob    int    `json:"yob" binding:"required"`
    Bio    string `json:"bio"`
}

func SetProfile(c *gin.Context) {

    userid, _ := c.Keys["userid"].(int64)
    username, _ := c.Keys["username"].(string)

    var json ProfileJson
    err := c.BindJSON(&json)
    LogError(err)

    db := cassandra.SharedSession()
    if err := db.Query(`UPDATE user SET phone = ?, avatar = ?, sex = ?, yob = ?, bio = ? WHERE id = ?`,
        json.Phone, json.Avatar, json.Sex, json.Yob, json.Bio, userid).Exec(); err != nil {
        LogError(err)
        c.AbortWithError(http.StatusBadGateway, err)
        return
    }

    if err := db.Query(`INSERT INTO user_by_phone (phone, username, id) VALUES (?, ?, ?)`,
        json.Phone, username, userid).Exec(); err != nil {
        LogError(err)
        c.AbortWithError(http.StatusBadGateway, err)
        return
    }

    // update cache
    u := &cache.User{userid, username, json.Avatar, json.Sex, json.Yob}
    cache.SetUserStruct(u)

    c.JSON(http.StatusOK, gin.H{
        "updated": "user/profile",
    })
    return
}

func GetProfile(c *gin.Context) {

}
