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
    "joyyapp.com/winkrock/idgen"
    . "joyyapp.com/winkrock/util"
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

type CreatePostResponse struct {
    PostId  int64  `json:"postid"`
    OwnerId int64  `json:"ownerid"`
    URL     string `json:"url"`
    Caption string `json:"caption"`
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
    query := h.DB.Query(`INSERT INTO timeline (userid, day, postid, ownerid, url, caption) VALUES (?, ?, ?, ?, ?, ?)`, 0, 0, 0, 0, "", "")

    for _, fid := range fids {
        query.Bind(fid, day, postid, userid, p.URL, p.Caption).Exec()
    }

    // write to userline, ignore write failures if any
    month := ThisMonth()
    query = h.DB.Query(`INSERT INTO userline (userid, month, postid, url, caption) VALUES (?, ?, ?, ?, ?)`, userid, month, postid, p.URL, p.Caption)
    query.Exec()

    response := &CreatePostResponse{
        PostId:  postid,
        OwnerId: userid,
        URL:     p.URL,
        Caption: p.Caption,
    }

    bytes, _ := json.Marshal(response)
    RespondData(w, bytes)
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

    fids, err := h.getFriendIds(userid)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    postid := idgen.NewID()
    day := ThisDay()

    // write an anti-post to all the friends timelines, including the owner's. ignore write failures if any
    fids = append(fids, userid)

    url := fmt.Sprintf(":anti_post[%d]", p.PostId)
    query := h.DB.Query(`INSERT INTO timeline (userid, day, postid, ownerid, url) VALUES (?, ?, ?, ?, ?)`, 0, 0, 0, 0, "")
    for _, fid := range fids {
        query.Bind(fid, day, postid, userid, url).Exec()
    }

    // delete original post from all the friends timeline, including the owner's. ignore write failures if any
    day = idgen.DayOf(p.PostId)
    query = h.DB.Query(`DELETE FROM timeline WHERE userid = ? AND day = ? AND postid = ?`, 0, 0, 0)
    for _, fid := range fids {
        query.Bind(fid, day, p.PostId).Exec()
    }

    // delete from userline
    month := idgen.MonthOf(p.PostId)
    query = h.DB.Query(`DELETE FROM userline WHERE userid = ? AND month = ? AND postid = ?`, userid, month, p.PostId)
    query.Exec()

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

type CreateCommentResponse struct {
    CommentId int64  `json:"commentid"`
    OwnerId   int64  `json:"ownerid"`
    PostId    int64  `json:"postid"`
    ReplyToId int64  `json:"replytoid"`
    Content   string `json:"content"`
}

func (h *Handler) CreateComment(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p CreateCommentParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    // a comment can be seen by the comment's author and the peer's mutual friends
    peerid := p.PosterId
    if p.ReplyToId > 0 {
        peerid = p.ReplyToId
    }

    fids, err := h.getMutualFriendIds(userid, peerid)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    commentid := idgen.NewID()

    // write the comment to all the mutal friends' commentlines, including the owner. ignore write failures if any
    query := h.DB.Query(`INSERT INTO commentline (userid, commentid, ownerid, postid, replytoid, content) VALUES (?, ?, ?, ?, ?)`, 0, 0, 0, 0, "", "")
    for _, fid := range fids {
        query.Bind(fid, commentid, userid, p.PostId, p.ReplyToId, p.Content).Exec()
    }

    response := &CreateCommentResponse{
        CommentId: commentid,
        OwnerId:   userid,
        PostId:    p.PostId,
        ReplyToId: p.ReplyToId,
        Content:   p.Content,
    }

    bytes, _ := json.Marshal(response)
    RespondData(w, bytes)
    return
}

/*
 * Delete a comment. The original comment will not be deleted in DB, instead, we create an "anti-comment" to make the original comment invisible
 */
type DeleteCommentParams struct {
    CommentId int64 `param:"commentid" validate:"required"`
    PostId    int64 `param:"postid" validate:"required"`
    PosterId  int64 `param:"posterid" validate:"required"`
    ReplyToId int64 `param:"replytoid"`
}

func (h *Handler) DeleteComment(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p DeleteCommentParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    // same as a normal comment, an anti-comment can be seen by the comment's author and the peer's mutual friends
    peerid := p.PosterId
    if p.ReplyToId > 0 {
        peerid = p.ReplyToId
    }

    fids, err := h.getMutualFriendIds(userid, peerid)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    commentid := idgen.NewID()
    content := fmt.Sprintf(":anti_comment[%d]", p.CommentId)

    // write the anti comment to all the mutal friends' commentlines. ignore write failures if any
    query := h.DB.Query(`INSERT INTO commentline (userid, commentid, ownerid, postid, replytoid, content) VALUES (?, ?, ?, ?, ?)`, 0, 0, 0, 0, "", "")
    for _, fid := range fids {
        query.Bind(fid, commentid, userid, p.PostId, p.ReplyToId, content).Exec()
    }

    // delete comment from all the friends commentlines, including the owner's. ignore write failures if any
    query = h.DB.Query(`DELETE FROM commentline WHERE userid = ? AND commentid = ?`, 0, 0)
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
    Day     int   `param:"day" validate:"min=150101"`
    SinceId int64 `param:"sinceid"`
}

func (h *Handler) ReadTimeline(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p TimelineParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    var query *gocql.Query
    if p.SinceId == 0 {
        query = h.DB.Query(`SELECT postid, ownerid, url, caption FROM timeline WHERE userid = ? AND day = ?`, userid, p.Day)
    } else {
        query = h.DB.Query(`SELECT postid, ownerid, url, caption FROM timeline WHERE userid = ? AND day = ? AND postid > ?`, userid, p.Day, p.SinceId)
    }

    iter := query.Consistency(gocql.One).Iter()
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
    UserId int64 `param:"userid" validate:"required"`
    Month  int   `param:"month" validate:"min=1501"`
}

func (h *Handler) ReadUserline(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p UserlineParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    iter := h.DB.Query(`SELECT postid, url, caption FROM userline WHERE userid = ? AND month = ?`, p.UserId, p.Month).Consistency(gocql.One).Iter()
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
    SinceId  int64 `param:"sinceid"`
    BeforeId int64 `param:"beforeid"`
}

func (h *Handler) ReadCommentline(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p CommentlineParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    stmt := `SELECT commentid, postid, replytoid, content FROM commentline WHERE userid = ? AND commentid > ? AND commentid < ?`
    iter := h.DB.Query(stmt, userid, p.SinceId, p.BeforeId).Consistency(gocql.One).Iter()
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
    s.Add(userid) // an user is a friend of himself
    return s, err
}

func (h *Handler) getMutualFriendIds(userid1, userid2 int64) ([]interface{}, error) {

    s1, err := h.getFriendIdSet(userid1)
    if err != nil {
        return nil, err
    }

    s2, err := h.getFriendIdSet(userid2)
    if err != nil {
        return nil, err
    }

    mutual := s1.Intersect(s2)

    return mutual.ToSlice(), nil
}
