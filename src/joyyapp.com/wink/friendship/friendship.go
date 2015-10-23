/*
 * friendship.go
 * user related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package friendship

import (
// "encoding/json"
// "gopkg.in/bluesuncorp/validator.v8"
// "github.com/gocql/gocql"
// . "joyyapp.com/wink/util"
// "net/http"
)

// type Handler struct {
//     DB *gocql.Session
// }

// type Friend struct {
//     Id       int64  `json:"id"`
//     Username string `json:"username"`
//     Region   int    `json:"region"`
// }

// func (h *Handler) GetFriendIds(userid int64) ([]int64, error) {

//     var fid int64
//     var fids = make([]int64, 0, 128) // an empty slice, with default capacity 128
//     iter := h.DB.Query(`SELECT dest_id FROM friendship WHERE userid = ?`, userid).Consistency(gocql.One).Iter()
//     for iter.Scan(&fid) {
//         fids = append(fids, fid)
//     }

//     err := iter.Close()
//     return fids, err
// }

// func (h *Handler) getFriends(userid int64) ([]*Friend, error) {

//     var fid int64
//     var fname string
//     var fregion int
//     var friend *Friend
//     var friends = make([]*Friend, 0, 120)

//     iter := h.DB.Query(`SELECT fid, fname, fregion FROM friendship WHERE userid = ?`, userid).Iter()
//     for iter.Scan(&fid, &fname, &fregion) {
//         friend = &Friend{fid, fname, fregion}
//         friends = append(friends, friend)
//     }

//     err := iter.Close()
//     return friends, err
// }

// type FriendshipParams struct {
//     Fid     int64  `json:"friend_id" binding:"required"`
//     Fname   string `json:"friend_name" binding:"required"`
//     Fregion int    `json:"friend_region" binding:"required"`
//     Region  int    `json:"own_region" binding:"required"`
// }

// func (h *Handler) Create(c *gin.Context) {

//     userid, _ := c.Keys["userid"].(int64)
//     username, _ := c.Keys["username"].(string)

//     var json FriendshipParams
//     err := c.BindJSON(&json)
//     LogError(err)

//     // add edge
//     if err := h.DB.Query(`INSERT INTO friendship (userid, fid, fname, fregion) VALUES (?, ?, ?, ?)`,
//         userid, json.Fid, json.Fname, json.Fregion).Exec(); err != nil {
//         LogError(err)
//         c.AbortWithError(http.StatusBadGateway, err)
//         return
//     }

//     // add reverse edge
//     if err := h.DB.Query(`INSERT INTO friendship (userid, fid, fname, fregion) VALUES (?, ?, ?, ?)`,
//         json.Fid, userid, username, json.Region).Exec(); err != nil {
//         LogError(err)
//         c.AbortWithError(http.StatusBadGateway, err)
//         return
//     }

//     c.JSON(http.StatusOK, gin.H{
//         "error": 0,
//     })
// }

// func (h *Handler) Update(c *gin.Context) {
// }

// func (h *Handler) Destroy(c *gin.Context) {
// }

// func (h *Handler) GetAll(c *gin.Context) {

//     userid, _ := c.Keys["userid"].(int64)
//     friends, err := h.getFriends(userid)
//     if err != nil {
//         LogError(err)
//         c.AbortWithError(http.StatusBadGateway, err)
//         return
//     }

//     bytes, err := json.Marshal(friends)
//     if err != nil {
//         LogError(err)
//         c.AbortWithError(http.StatusBadGateway, err)
//         return
//     }

//     c.Data(http.StatusOK, "application/json", bytes)
// }
