/*
 * post.go
 * post related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package post

import (
    "encoding/json"
    "fmt"
    "github.com/deckarep/golang-set"
    "github.com/gocql/gocql"
    "joyyapp.com/wink/idgen"
    . "joyyapp.com/wink/util"
    "net/http"
)

type Handler struct {
    DB *gocql.Session
}

/*
 * Create a post
 */
type CreatePostParams struct {
    URL     string `param:"url" validate:"required"`
    Caption string `param:"caption"`
}

func (h *Handler) CreatePost(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p CreatePostParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    fids, err := h.getFriendIds(userid)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    postid := idgen.NewID()
    day := ThisDay()

    // write to all the friends timelines, including the owner. ignore write failures if any
    fids = append(fids, userid)
    query := h.DB.Query(`INSERT INTO timeline (userid, day, postid, url, caption) VALUES (?, ?, ?, ?, ?)`, 0, 0, 0, "", "")

    for _, fid := range fids {
        query.Bind(fid, day, postid, p.URL, p.Caption).Exec()
    }

    // write to userline, ignore write failures if any
    month := ThisMonth()
    query = h.DB.Query(`INSERT INTO userline (userid, month, postid, url, caption) VALUES (?, ?, ?, ?, ?)`, userid, month, postid, p.URL, p.Caption)
    query.Exec()

    message := fmt.Sprintf("{postid:%v}", postid)
    RespondData(w, []byte(message))
    return
}

/*
 * Delete a post
 */
type DeletePostParams struct {
    PostId int64 `param:"postid" validate:"required"`
}

func (h *Handler) DeletePost(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p DeletePostParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    // delete from userline
    month := idgen.MonthOf(p.PostId)
    query := h.DB.Query(`DELETE FROM userline WHERE userid = ? AND month = ? AND postid = ?`, userid, month, p.PostId)

    // delete failure may due to DB failure or incorrect postid
    if err := query.Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    fids, err := h.getFriendIds(userid)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    // delete post from all the friends timelines, including the owner. ignore write failures if any
    fids = append(fids, userid)
    day := idgen.DayOf(p.PostId)
    query = h.DB.Query(`DELETE FROM timeline WHERE userid = ? AND day = ? AND postid = ?`, 0, 0, 0)

    for _, fid := range fids {
        query.Bind(fid, day, p.PostId).Exec()
    }

    RespondOK(w)
    return
}

/*
 * Create a comment
 */
type CreateCommentParams struct {
    PostId    int64  `param:"postid" validate:"required"`
    PosterId  int64  `param:"posterid" validate:"required"`
    ReplyToId int64  `param:"replytoid"`
    Content   string `param:"content" validate:"required"`
}

func (h *Handler) CreateComment(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p CreateCommentParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    fids, err := h.getMutualFriendIds(userid, p.PosterId)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    fids = append(fids, userid)
    commentid := idgen.NewID()

    // write the comment to all the mutal friends' commentlines, including the owner. ignore write failures if any
    query := h.DB.Query(`INSERT INTO commentline (userid, commentid, postid, replytoid, content) VALUES (?, ?, ?, ?, ?)`, 0, 0, 0, "", "")
    for _, fid := range fids {
        query.Bind(fid, commentid, p.PostId, p.ReplyToId, p.Content).Exec()
    }

    message := fmt.Sprintf("{commentid:%v}", commentid)
    RespondData(w, []byte(message))
    return
}

/*
 * Delete a comment
 */
type DeleteCommentParams struct {
    CommentId int64 `param:"postid" validate:"required"`
    PosterId  int64 `param:"posterid" validate:"required"`
}

func (h *Handler) DeleteComment(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p DeleteCommentParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    fids, err := h.getMutualFriendIds(userid, p.PosterId)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    fids = append(fids, userid)

    // delete comment from all the friends timelines, including the owner. ignore write failures if any
    query := h.DB.Query(`DELETE FROM commentline WHERE userid = ? AND commentid = ?`, 0, 0)

    for _, fid := range fids {
        query.Bind(fid, p.CommentId).Exec()
    }

    RespondOK(w)
    return
}

/*
 * Read timeline
 */
type TimelineParams struct {
    Day int `param:"day" validate:"min=150101"`
}

func (h *Handler) ReadTimeline(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p TimelineParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    iter := h.DB.Query(`SELECT postid, url, caption FROM timeline WHERE userid = ? AND day = ?`, userid, p.Day).Consistency(gocql.One).Iter()
    posts, err := iter.SliceMap()
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    bytes, err := json.Marshal(posts)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondData(w, bytes)
    return
}

/*
 * Read userline
 */
type UserlineParams struct {
    Month int `param:"month" validate:"min=1501"`
}

func (h *Handler) ReadUserline(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p UserlineParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    iter := h.DB.Query(`SELECT postid, url, caption FROM userline WHERE userid = ? AND month = ?`, userid, p.Month).Consistency(gocql.One).Iter()
    posts, err := iter.SliceMap()
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    bytes, err := json.Marshal(posts)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondData(w, bytes)
    return
}

/*
 * Read commentline
 */
type CommentlineParams struct {
    SinceID int `param:"sinceid"`
}

func (h *Handler) ReadCommentline(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p CommentlineParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    iter := h.DB.Query(`SELECT commentid, postid, replytoid, content FROM commentline WHERE userid = ? AND commentid > ?`, userid, p.SinceID).Consistency(gocql.One).Iter()
    comments, err := iter.SliceMap()
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    bytes, err := json.Marshal(comments)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondData(w, bytes)
    return
}

func (h *Handler) getFriendIds(userid int64) ([]interface{}, error) {

    var fids = make([]interface{}, 0, 128) // an empty slice, with default capacity 128
    var fid int64
    iter := h.DB.Query(`SELECT fid FROM friend WHERE userid = ? LIMIT 500`, userid).Consistency(gocql.One).Iter()
    for iter.Scan(&fid) {
        fids = append(fids, fid)
    }

    err := iter.Close()
    return fids, err
}

func (h *Handler) getFriendIdSet(userid int64) (mapset.Set, error) {

    s := mapset.NewThreadUnsafeSet()
    var fid int64

    iter := h.DB.Query(`SELECT fid FROM friend WHERE userid = ? LIMIT 500`, userid).Consistency(gocql.One).Iter()
    for iter.Scan(&fid) {
        s.Add(fid)
    }
    err := iter.Close()
    return s, err
}

func (h *Handler) getMutualFriendIds(userid1, userid2 int64) ([]interface{}, error) {

    s1, err := h.getFriendIdSet(userid1)
    if err != nil {
        return nil, err
    }

    mutual := make([]interface{}, 16)
    var fid int64
    iter := h.DB.Query(`SELECT fid FROM friend WHERE userid = ? LIMIT 500`, userid2).Consistency(gocql.One).Iter()
    for iter.Scan(&fid) {
        if s1.Contains(fid) {
            mutual = append(mutual, fid)
        }
    }
    err = iter.Close()

    return mutual, err
}
