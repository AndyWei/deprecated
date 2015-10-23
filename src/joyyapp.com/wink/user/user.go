/*
 * user.go
 * user related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package user

import (
    // "encoding/json"
    "github.com/gocql/gocql"
    // . "joyyapp.com/wink/util"
    // "net/http"
)

type Handler struct {
    DB *gocql.Session
}

// /*
//  * Profile endpoints
//  */
// type ProfileParams struct {
//     Phone  int64  `json:"phone" binding:"required"`
//     Region int    `json:"region" binding:"required"`
//     Sex    int    `json:"sex" binding:"required"`
//     Yob    int    `json:"yob" binding:"required"`
//     Bio    string `json:"bio"`
// }

// func (h *Handler) SetProfile(c *gin.Context) {

//     userid, _ := c.Keys["userid"].(int64)
//     username, _ := c.Keys["username"].(string)

//     var json ProfileParams
//     err := c.BindJSON(&json)
//     LogError(err)

//     if err := h.DB.Query(`UPDATE user SET phone = ?, region = ?, sex = ?, yob = ?, bio = ? WHERE id = ?`,
//         json.Phone, json.Region, json.Sex, json.Yob, json.Bio, userid).Exec(); err != nil {
//         LogError(err)
//         c.AbortWithError(http.StatusBadGateway, err)
//         return
//     }

//     if err := h.DB.Query(`INSERT INTO user_by_phone (phone, username, id) VALUES (?, ?, ?)`,
//         json.Phone, username, userid).Exec(); err != nil {
//         LogError(err)
//         c.AbortWithError(http.StatusBadGateway, err)
//         return
//     }

//     c.JSON(http.StatusOK, gin.H{"error": 0})
//     return
// }

// func (h *Handler) GetProfile(c *gin.Context) {

//     userid, _ := c.Keys["userid"].(int64)

//     m := make(map[string]interface{})
//     if err := h.DB.Query(`SELECT username, deleted, phone, region, sex, yob, bio FROM user WHERE id = ? LIMIT 1`,
//         userid).Consistency(gocql.One).MapScan(testMap); err != nil {
//         LogError(err)
//         c.JSON(http.StatusNotFound, gin.H{"error": 1})
//         return
//     }

//     bytes, err := json.Marshal(m)
//     if err != nil {
//         LogError(err)
//         c.AbortWithError(http.StatusBadGateway, err)
//         return
//     }

//     c.Data(http.StatusOK, "application/json", bytes)
// }
