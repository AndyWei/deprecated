/*
 * friendship.go
 * friendship related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package friendship

import (
    "encoding/json"
    "github.com/gocql/gocql"
    . "joyyapp.com/wink/util"
    "net/http"
)

type Handler struct {
    DB *gocql.Session
}

type CreateFriendshipRequest struct {
    Fid     int64  `param:"fid" validate:"required"`
    Fname   string `param:"fname" validate:"min=2,max=40"`
    Fregion int    `param:"fregion" validate:"min=0,max=2"`
    Region  int    `param:"region" validate:"min=0,max=2"`
}

func (h *Handler) Create(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var r CreateFriendshipRequest
    if err := ParseAndCheck(req, &r); err != nil {
        ReplyError(w, err.Error(), http.StatusBadRequest)
        return
    }

    // add edge
    query := h.DB.Query(`INSERT INTO friendship (userid, fid, fname, fregion) VALUES (?, ?, ?, ?)`, userid, r.Fid, r.Fname, r.Fregion)
    if err := query.Exec(); err != nil {
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    // add reverse edge
    if err := query.Bind(r.Fid, userid, username, r.Region).Exec(); err != nil {
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    ReplyOK(w)
    return
}

type DestroyFriendshipRequest struct {
    Fid int64 `param:"fid" validate:"required"`
}

func (h *Handler) Delete(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var r DestroyFriendshipRequest
    if err := ParseAndCheck(req, &r); err != nil {
        ReplyError(w, err.Error(), http.StatusBadRequest)
        return
    }

    // delete edge
    query := h.DB.Query(`DELETE FROM friendship WHERE userid = ? AND fid = ?`, userid, r.Fid)
    if err := query.Exec(); err != nil {
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    // delete reverse edge
    if err := query.Bind(r.Fid, userid).Exec(); err != nil {
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    ReplyOK(w)
    return
}

func (h *Handler) GetAll(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    iter := h.DB.Query(`SELECT fid, fname, fregion FROM friendship WHERE userid = ?`, userid).Iter()
    friends, err := iter.SliceMap()
    if err != nil {
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    bytes, err := json.Marshal(friends)
    if err != nil {
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    ReplyData(w, bytes)
}
