/*
 * edge.go
 * edge related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package edge

import (
    "encoding/json"
    "fmt"
    "github.com/gocql/gocql"
    . "joyyapp.com/wink/util"
    "net/http"
)

type Handler struct {
    DB *gocql.Session
}

const (
    kInviteTable     = "invite"
    kFriendshipTable = "friendship"
)

/* Invite */
type CreateInviteParams struct {
    YRS          int   `param:"yrs" validate:"required"`
    FriendUserId int64 `param:"fid" validate:"required"`
}

func (h *Handler) CreateInvite(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p CreateInviteParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    // check if the friend has already invited the user. If he has, then the friendship can be created directly
    // m, err := h.readEdge(kInviteTable, r.FriendUserId, userid)
    // if err != nil {
    //     RespondError(w, err, http.StatusBadGateway)
    //     return
    // }

    // if m is not empty {

    // }

    if err := h.createEdge(kInviteTable, p.FriendUserId, userid, username, p.YRS); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

type DeleteInviteParams struct {
    FriendUserId int64 `param:"fid" validate:"required"`
}

func (h *Handler) DeleteInvite(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p DeleteInviteParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    if err := h.deleteEdge(kInviteTable, false, userid, p.FriendUserId); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

/* Friendship*/
type CreateFriendshipParams struct {
    FriendUserId   int64  `param:"fid" validate:"required"`
    FriendUsername string `param:"fname" validate:"min=2,max=40"`
    FriendYRS      int    `param:"fyrs" validate:"required"`
    UserYRS        int    `param:"yrs" validate:"required"`
}

func (h *Handler) CreateFriendship(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p CreateFriendshipParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    if err := h.createEdge(kFriendshipTable, userid, p.FriendUserId, p.FriendUsername, p.FriendYRS); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    if err := h.createEdge(kFriendshipTable, p.FriendUserId, userid, username, p.UserYRS); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

type DeleteFriendshipParams struct {
    FriendUserId int64 `param:"fid" validate:"required"`
}

func (h *Handler) DeleteFriendship(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p DeleteFriendshipParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    if err := h.deleteEdge(kFriendshipTable, true, userid, p.FriendUserId); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

func (h *Handler) ReadInvites(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    h.readEdgesAndRespond(w, kInviteTable, userid)
}

func (h *Handler) ReadFriendships(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    h.readEdgesAndRespond(w, kFriendshipTable, userid)
}

func (h *Handler) createEdge(table string, values ...interface{}) (err error) {
    format := "INSERT INTO %v (userid, fid, fname, fyrs) VALUES (?, ?, ?, ?)"
    stmt := fmt.Sprintf(format, table)
    if err := h.DB.Query(stmt, values...).Exec(); err != nil {
        return err
    }
    return nil
}

func (h *Handler) deleteEdge(table string, bidi bool, src, dest int64) (err error) {
    format := "DELETE FROM %v WHERE userid = ? AND fid = ?"
    stmt := fmt.Sprintf(format, table)
    query := h.DB.Query(stmt, src, dest)

    if err := query.Exec(); err != nil {
        return err
    }

    if bidi {
        if err := query.Bind(dest, src).Exec(); err != nil {
            return err
        }
    }
    return nil
}

func (h *Handler) readEdge(table string, userid, fid int64) (row map[string]interface{}, err error) {
    format := "SELECT fid, fname, fyrs FROM %v WHERE userid = ? AND fid = ?"
    stmt := fmt.Sprintf(format, table)
    m := make(map[string]interface{})

    if err := h.DB.Query(stmt, userid, fid).Consistency(gocql.One).MapScan(m); err != nil {
        return nil, err
    }

    return m, nil
}

func (h *Handler) readEdgesAndRespond(w http.ResponseWriter, table string, userid int64) {
    format := "SELECT fid, fname, fyrs FROM %v WHERE userid = ?"
    stmt := fmt.Sprintf(format, table)
    iter := h.DB.Query(stmt, userid).Consistency(gocql.One).Iter()
    results, err := iter.SliceMap()
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    bytes, err := json.Marshal(results)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondData(w, bytes)
}
