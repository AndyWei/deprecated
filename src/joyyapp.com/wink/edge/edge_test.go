/*
 * edge_test.go
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package edge

import (
    "encoding/json"
    "fmt"
    "github.com/stretchr/testify/assert"
    "joyyapp.com/wink/cassandra"
    . "joyyapp.com/wink/util"
    "net/http"
    "net/http/httptest"
    "strings"
    "testing"
)

var AddFriendTests = []struct {
    userid   int64
    username string
    yrs      int
    fid      int64
    fname    string
    fyrs     int
}{
    {1234567890000, "user0", 1, 1234567890001, "user1", 1},
    {1234567890000, "user0", 1, 1234567890002, "user2", 1},
    {1234567890000, "user0", 1, 1234567890003, "user3", 2},
    {1234567890000, "user0", 1, 1234567890004, "user4", 2},
}

func TestAddFriend(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, t := range AddFriendTests {

        body := fmt.Sprintf("yrs=%v&fid=%v&fname=%v&fyrs=%v", t.yrs, t.fid, t.fname, t.fyrs)
        req, _ := http.NewRequest("POST", "/v1/friend/add", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.AddFriend(resp, req, t.userid, t.username)

        assert.Equal(http.StatusOK, resp.Code, "should response correct status code")
    }
}

var ReadFriendsTests = []struct {
    fid   int64
    fname string
    fyrs  int
}{
    {1234567890001, "user1", 1},
    {1234567890002, "user2", 1},
    {1234567890003, "user3", 2},
    {1234567890004, "user4", 2},
}

type Friend struct {
    Fid   int64  `json:"fid"`
    Fname string `json:"fname"`
    Fyrs  int    `json:"fyrs"`
}

func TestReadFriends(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    userid := int64(1234567890000)
    username := "user0"
    yrs := 1

    for _, t := range ReadFriendsTests {

        body := fmt.Sprintf("yrs=%v&fid=%v&fname=%v&fyrs=%v", yrs, t.fid, t.fname, t.fyrs)
        req, _ := http.NewRequest("POST", "/v1/friend/add", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.AddFriend(resp, req, userid, username)

        assert.Equal(http.StatusOK, resp.Code, "should response correct status code")
    }

    req, _ := http.NewRequest("GET", "/v1/friend", nil)
    resp := httptest.NewRecorder()
    h.ReadFriends(resp, req, userid, username)

    bytes := resp.Body.Bytes()

    var r []Friend
    err := json.Unmarshal(bytes, &r)
    LogError(err)

    assert.Nil(err)
    assert.Equal(4, len(r), "should store friends in DB")
}
