/*
 * friendship_test.go
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package friendship

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

var CreateFriendshipTests = []struct {
    userid   int64
    username string
    region   int
    fid      int64
    fname    string
    fregion  int
}{
    {1234567890000, "user0", 0, 1234567890001, "user1", 0},
    {1234567890000, "user0", 0, 1234567890002, "user2", 1},
    {1234567890000, "user0", 0, 1234567890003, "user3", 2},
    {1234567890000, "user0", 0, 1234567890004, "user4", 2},
}

func TestCreateFriendship(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, t := range CreateFriendshipTests {

        body := fmt.Sprintf("region=%v&fid=%v&fname=%v&fregion=%v", t.region, t.fid, t.fname, t.fregion)
        req, _ := http.NewRequest("POST", "/v1/friendship/create", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.Create(resp, req, t.userid, t.username)

        assert.Equal(http.StatusOK, resp.Code, "should response correct status code")
    }
}

var GetFriendshipTests = []struct {
    fid     int64
    fname   string
    fregion int
}{
    {1234567890001, "user1", 0},
    {1234567890002, "user2", 1},
    {1234567890003, "user3", 2},
    {1234567890004, "user4", 2},
}

type Friend struct {
    Fid     int64  `json:"fid"`
    Fname   string `json:"fname"`
    Fregion int    `json:"fregion"`
}

func TestGetFriendship(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    userid := int64(1234567890000)
    username := "user0"
    region := 0

    for _, t := range GetFriendshipTests {

        body := fmt.Sprintf("region=%v&fid=%v&fname=%v&fregion=%v", region, t.fid, t.fname, t.fregion)
        req, _ := http.NewRequest("POST", "/v1/friendship/create", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.Create(resp, req, userid, username)

        assert.Equal(http.StatusOK, resp.Code, "should response correct status code")
    }

    req, _ := http.NewRequest("GET", "/v1/friendship", nil)
    resp := httptest.NewRecorder()
    h.GetAll(resp, req, userid, username)

    bytes := resp.Body.Bytes()

    var r []Friend
    err := json.Unmarshal(bytes, &r)
    LogError(err)

    assert.Nil(err)
    assert.Equal(4, len(r), "should store friends in DB")
}
