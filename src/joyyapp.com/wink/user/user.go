/*
 * user.go
 * user related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package user

import (
    "encoding/json"
    "github.com/gin-gonic/gin"
    "github.com/gocql/gocql"
    "joyyapp.com/wink/cache"
    "joyyapp.com/wink/cassandra"
    . "joyyapp.com/wink/util"
    "net/http"
)

type Friend struct {
    Id       int64  `json:"id"`
    Username string `json:"username"`
    Region   int    `json:"region"`
}

func GetFriendIds(userid int64) ([]int64, error) {

    session := cassandra.SharedSession()
    var fid int64
    var fids = make([]int64, 0, 128) // an empty slice, with default capacity 128
    iter := session.Query(`SELECT dest_id FROM friendship WHERE userid = ?`, userid).Consistency(gocql.One).Iter()
    for iter.Scan(&fid) {
        fids = append(fids, fid)
    }

    err := iter.Close()
    return fids, err
}

func getFriends(userid int64) ([]*Friend, error) {

    session := cassandra.SharedSession()

    var fid int64
    var fname string
    var fregion int
    var friend *Friend
    var friends = make([]*Friend, 0, 120)

    iter := session.Query(`SELECT fid, fname, fregion FROM friendship WHERE userid = ?`, userid).Iter()
    for iter.Scan(&fid, &fname, &fregion) {
        friend = &Friend{fid, fname, fregion}
        friends = append(friends, friend)
    }

    err := iter.Close()
    return friends, err
}

/*
 * Profile endpoints
 */
type ProfileParams struct {
    Phone  int64  `json:"phone" binding:"required"`
    Region int    `json:"region" binding:"required"`
    Sex    int    `json:"sex" binding:"required"`
    Yob    int    `json:"yob" binding:"required"`
    Bio    string `json:"bio"`
}

func SetProfile(c *gin.Context) {

    userid, _ := c.Keys["userid"].(int64)
    username, _ := c.Keys["username"].(string)

    var json ProfileParams
    err := c.BindJSON(&json)
    LogError(err)

    session := cassandra.SharedSession()

    if err := session.Query(`UPDATE user SET phone = ?, region = ?, sex = ?, yob = ?, bio = ? WHERE id = ?`,
        json.Phone, json.Region, json.Sex, json.Yob, json.Bio, userid).Exec(); err != nil {
        LogError(err)
        c.AbortWithError(http.StatusBadGateway, err)
        return
    }

    if err := session.Query(`INSERT INTO user_by_phone (phone, username, id) VALUES (?, ?, ?)`,
        json.Phone, username, userid).Exec(); err != nil {
        LogError(err)
        c.AbortWithError(http.StatusBadGateway, err)
        return
    }

    // update cache
    u := &cache.User{userid, username, json.Region, json.Sex, json.Yob}
    cache.SetUserStruct(u)

    c.JSON(http.StatusOK, gin.H{
        "error": 0,
    })
    return
}

func GetProfile(c *gin.Context) {

    userid, _ := c.Keys["userid"].(int64)
    u, err := cache.GetUserStruct(userid)
    LogError(err)
    if err != nil {
        c.AbortWithError(http.StatusNotFound, err)
        return
    }

    // Note json marshaler is used instead of gin.H{}
    jsondata, err := json.Marshal(u)
    if err != nil {
        LogError(err)
        c.AbortWithError(http.StatusBadGateway, err)
        return
    }

    c.Data(http.StatusOK, "application/json", jsondata)
}

/*
 * Friendship endpoints
 */
type FriendshipParams struct {
    Fid     int64  `json:"friend_id" binding:"required"`
    Fname   string `json:"friend_name" binding:"required"`
    Fregion int    `json:"friend_region" binding:"required"`
    Region  int    `json:"own_region" binding:"required"`
}

func CreateFriendship(c *gin.Context) {

    userid, _ := c.Keys["userid"].(int64)
    username, _ := c.Keys["username"].(string)

    var json FriendshipParams
    err := c.BindJSON(&json)
    LogError(err)

    session := cassandra.SharedSession()

    // add edge
    if err := session.Query(`INSERT INTO friendship (userid, fid, fname, fregion) VALUES (?, ?, ?, ?)`,
        userid, json.Fid, json.Fname, json.Fregion).Exec(); err != nil {
        LogError(err)
        c.AbortWithError(http.StatusBadGateway, err)
        return
    }

    // add reverse edge
    if err := session.Query(`INSERT INTO friendship (userid, fid, fname, fregion) VALUES (?, ?, ?, ?)`,
        json.Fid, userid, username, json.Region).Exec(); err != nil {
        LogError(err)
        c.AbortWithError(http.StatusBadGateway, err)
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "error": 0,
    })
}

func UpdateFriendship(c *gin.Context) {
}

func DestroyFriendship(c *gin.Context) {
}

func GetFriends(c *gin.Context) {

    userid, _ := c.Keys["userid"].(int64)
    friends, err := getFriends(userid)
    if err != nil {
        LogError(err)
        c.AbortWithError(http.StatusBadGateway, err)
        return
    }

    jsondata, err := json.Marshal(friends)
    if err != nil {
        LogError(err)
        c.AbortWithError(http.StatusBadGateway, err)
        return
    }

    c.Data(http.StatusOK, "application/json", jsondata)
}
