/*
 * friendship_test.go
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package friendship

import (
// "encoding/json"
// "github.com/stretchr/testify/assert"
// "io/ioutil"
// "net/http"
// "strings"
// "testing"
)

// func createFriendshipParams(fid int64, fname string, fregion, region int) *FriendshipParams {
//     return &FriendshipParams{Fid: fid, Fname: fname, Fregion: fregion, Region: region}
// }

// func TestCreate(t *testing.T) {

//     assert := assert.New(t)

//     dummyUsername := "dummy_for_friendship"
//     _, tokenString := signup(dummyUsername, "profile")

//     // set profile first
//     fid := int64(14008009000)
//     fname := "bff"
//     fregion := 0
//     region := 1

//     payload := createFriendshipParams(fid, fname, fregion, region)
//     jsondata, _ := json.Marshal(payload)
//     post_data := strings.NewReader(string(jsondata))

//     // request
//     url := "http://localhost:8000/v1/user/friendship/create"
//     req, _ := http.NewRequest("POST", url, post_data)
//     req.Header.Set("Content-Type", "application/json")
//     req.Header.Set("Authorization", "Bearer "+tokenString)

//     // send
//     resp, err := client.Do(req)
//     assert.Nil(err)

//     // get friends
//     url = "http://localhost:8000/v1/user/friends"
//     req, _ = http.NewRequest("GET", url, nil)
//     req.Header.Set("Authorization", "Bearer "+tokenString)
//     resp, err = client.Do(req)
//     assert.Nil(err)
//     assert.Equal(http.StatusOK, resp.StatusCode, "should response StatusOK")
//     body, err := ioutil.ReadAll(resp.Body)
//     defer resp.Body.Close()
//     assert.Nil(err)

//     var friends []Friend
//     err = json.Unmarshal(body, &friends)
//     assert.Nil(err)

//     var friend Friend = friends[0]
//     assert.Equal(fid, friend.Id, "should store correct userid in DB")
//     assert.Equal(fname, friend.Username, "should store correct username in DB")
//     assert.Equal(fregion, friend.Region, "should store correct region in DB")
// }
