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
    "joyyapp.com/winkrock/cassandra"
    . "joyyapp.com/winkrock/util"
    "net/http"
    "net/http/httptest"
    "strings"
    "testing"
)

type Friend struct {
    Fid   int64  `json:"fid"`
    Fname string `json:"fname"`
    Fyrs  int64  `json:"fyrs"`
}

type Initiate struct {
    InitiateId int64  `json:"id"`
    Fid        int64  `json:"fid"`
    Fname      string `json:"fname"`
    Fyrs       int64  `json:"fyrs"`
    Phone      int64  `json:"phone"`
}

var InviteTests = []struct {
    userid   int64
    username string
    yrs      int64
    phone    int64
}{
    {1234567890001, "user1", 1, 14158009001},
    {1234567890002, "user2", 1, 14158009002},
    {1234567890003, "user3", 2, 14158009003},
    {1234567890004, "user4", 2, 14158009004},
}

func TestInvite(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    myId := int64(1234567890000)
    myName := "user0"
    myYRS := 1

    // all the invites should be created successfully
    for _, t := range InviteTests {

        body := fmt.Sprintf("yrs=%v&phone=%v&fid=%v&fname=%v&fyrs=%v", t.yrs, t.phone, myId, myName, myYRS)
        req, _ := http.NewRequest("POST", "/v1/invite/create", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.CreateInvite(resp, req, t.userid, t.username)
        assert.Equal(http.StatusOK, resp.Code, "should response correct status code")
    }

    // all the invites should be read out successfully
    req, _ := http.NewRequest("GET", "/v1/invites?sinceid=0&beforeid=9223372036854775807", nil)
    resp := httptest.NewRecorder()
    h.ReadInvites(resp, req, myId, myName)
    bytes := resp.Body.Bytes()

    var initiates []Initiate
    err := json.Unmarshal(bytes, &initiates)
    LogError(err)

    assert.Nil(err)
    assert.Equal(len(InviteTests), len(initiates), "should store all invites from DB")

    // accept invites
    for _, i := range initiates {
        body := fmt.Sprintf("id=%v&fid=%v&fname=%v&fyrs=%v&yrs=%v", i.InitiateId, i.Fid, i.Fname, i.Fyrs, myYRS)
        req, _ := http.NewRequest("POST", "/v1/invite/accept", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.AcceptInvite(resp, req, myId, myName)
        assert.Equal(http.StatusOK, resp.Code, "should response correct status code")
    }

    friends := h.validateFriendsCount(assert, myId, myName, len(InviteTests))
    h.deleteFriends(assert, friends, myId, myName)
    h.validateFriendsCount(assert, myId, myName, 0)
}

var WinkTests = []struct {
    userid   int64
    username string
    yrs      int64
}{
    {1234567890001, "user1", 1},
    {1234567890002, "user2", 1},
    {1234567890003, "user3", 2},
    {1234567890004, "user4", 2},
}

func TestWink(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    myId := int64(1234567890000)
    myName := "user0"
    myYRS := 1

    // all the invites should be created successfully
    for _, t := range WinkTests {

        body := fmt.Sprintf("yrs=%v&fid=%v&fname=%v&fyrs=%v", t.yrs, myId, myName, myYRS)
        req, _ := http.NewRequest("POST", "/v1/wink/create", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.CreateWink(resp, req, t.userid, t.username)
        assert.Equal(http.StatusOK, resp.Code, "should response correct status code")
    }

    // all the winks should be read out successfully
    req, _ := http.NewRequest("GET", "/v1/winks?sinceid=0&beforeid=9223372036854775807", nil)
    resp := httptest.NewRecorder()
    h.ReadWinks(resp, req, myId, myName)
    bytes := resp.Body.Bytes()

    var initiates []Initiate
    err := json.Unmarshal(bytes, &initiates)
    LogError(err)

    assert.Nil(err)
    assert.Equal(len(WinkTests), len(initiates), "should store all invites from DB")

    // accept winks
    for _, i := range initiates {
        body := fmt.Sprintf("id=%v&fid=%v&fname=%v&fyrs=%v&yrs=%v", i.InitiateId, i.Fid, i.Fname, i.Fyrs, myYRS)
        req, _ := http.NewRequest("POST", "/v1/wink/accept", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.AcceptWink(resp, req, myId, myName)
        assert.Equal(http.StatusOK, resp.Code, "should response correct status code")
    }

    friends := h.validateFriendsCount(assert, myId, myName, len(WinkTests))
    h.deleteFriends(assert, friends, myId, myName)
    h.validateFriendsCount(assert, myId, myName, 0)
}

func (h *Handler) validateFriendsCount(assert *assert.Assertions, userid int64, username string, fcount int) []Friend {
    req, _ := http.NewRequest("GET", "/v1/friends", nil)
    resp := httptest.NewRecorder()
    h.ReadFriends(resp, req, userid, username)

    bytes := resp.Body.Bytes()

    var friends []Friend
    err := json.Unmarshal(bytes, &friends)
    LogError(err)

    assert.Nil(err)
    assert.Equal(fcount, len(friends), "should store friends in DB")

    return friends
}

func (h *Handler) deleteFriends(assert *assert.Assertions, friends []Friend, userid int64, username string) {
    for _, friend := range friends {
        body := fmt.Sprintf("fid=%v", friend.Fid)
        req, _ := http.NewRequest("POST", "/v1/friend/delete", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.DeleteFriend(resp, req, userid, username)
        assert.Equal(http.StatusOK, resp.Code, "should response correct status code")
    }
}
