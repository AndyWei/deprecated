/*
 * post_test.go
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package post

import (
    "encoding/json"
    "fmt"
    "github.com/stretchr/testify/assert"
    "joyyapp.com/winkrock/cassandra"
    . "joyyapp.com/winkrock/util"
    "net/http"
    "net/http/httptest"
    "net/url"
    "strings"
    "testing"
)

var userid int64 = int64(109511996335980544)
var username string = "user0"

var Friends = []struct {
    fid   int64
    fname string
    fyrs  int
}{
    {1234567890001, "user1", 2},
    {1234567890002, "user2", 1},
    {1234567890003, "user3", 2},
    {1234567890004, "user4", 2},
    {1234567890005, "user5", 1},
    {1234567890006, "user6", 1},
    {1234567890007, "user7", 2},
    {1234567890008, "user8", 2},
    {1234567890009, "user9", 1},
    {1234567890010, "userA", 1},
    {1234567890011, "userB", 2},
    {1234567890012, "userC", 2},
    {1234567890013, "userD", 2},
    {1234567890014, "userE", 2},
    {1234567890015, "userF", 1},
    {1234567890016, "userG", 1},
    {1234567890017, "userH", 2},
    {1234567890018, "userI", 2},
    {1234567890019, "userJ", 1},
    {1234567890020, "userK", 1},
}

func (h *Handler) prepareFriends() {
    query := h.DB.Query(`INSERT INTO friend (userid, fid, fname, fyrs) VALUES (?, ?, ?, ?)`, 0, 0, 0, 0)

    for _, r := range Friends {
        query.Bind(userid, r.fid, r.fname, r.fyrs).Exec()
    }
}

type Post struct {
    Postid  int64  `json:"postid"`
    URL     string `json:"url"`
    Caption string `json:"caption"`
}

var PostTests = []struct {
    url     string
    caption string
}{
    {"url1", "caption1 #%^$"},
    {"url2", "caption2 *&@("},
    {"url3", "caption3 09&^@好"},
    {"url4", ""},
}

func TestCreatePost(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    h.prepareFriends()
    for _, t := range PostTests {

        body := fmt.Sprintf("url=%v&caption=%v", t.url)
        if len(t.caption) > 0 {
            body += fmt.Sprintf("&caption=%v", url.QueryEscape(t.caption))
        }
        req, _ := http.NewRequest("POST", "/v1/post/create", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.CreatePost(resp, req, userid, username)

        assert.Equal(http.StatusOK, resp.Code, "should response correct status code")
    }

    // check userline
    month := ThisMonth()
    query := fmt.Sprintf("/v1/post/userline?month=%v", month)
    req, _ := http.NewRequest("GET", query, nil)
    resp := httptest.NewRecorder()
    h.ReadUserline(resp, req, userid, username)

    bytes := resp.Body.Bytes()

    var r []Post
    err := json.Unmarshal(bytes, &r)
    LogError(err)

    assert.Nil(err)
    assert.Equal(4, len(r), "should store all the created posts in userline")

    // check friends' timeline
    day := ThisDay()
    query = fmt.Sprintf("/v1/post/timeline?day=%v", day)
    req, _ = http.NewRequest("GET", query, nil)

    for _, f := range Friends {

        resp := httptest.NewRecorder()
        h.ReadTimeline(resp, req, f.fid, f.fname)
        bytes := resp.Body.Bytes()

        var r []Post
        err := json.Unmarshal(bytes, &r)
        LogError(err)

        assert.Nil(err)
        assert.Equal(4, len(r), "should store all the created posts in friend's timeline")
    }
}
