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
    . "joyyapp.com/winkrock/util"
    "net/http"
)

type Handler struct {
    DB *gocql.Session
}

const (
    kFriend           = "friend"
    kAddFriendStmt    = "INSERT INTO friend (userid, fid, fname, fyrs) VALUES (?, ?, ?, ?)"
    kRemoveFriendStmt = "DELETE FROM friend WHERE userid = ? AND fid = ?"
    kReadFriendsStmt  = "SELECT fid, fname, fyrs FROM friend WHERE userid = ?"

    kInvite           = "invite"
    kCreateInviteStmt = "INSERT INTO invite (userid, fid, fname, fyrs) VALUES (?, ?, ?, ?)"
    kDeleteInviteStmt = "DELETE FROM invite WHERE userid = ? AND fid = ?"
    kReadInvitesStmt  = "SELECT fid, fname, fyrs FROM invite WHERE userid = ?"

    kWink           = "wink"
    kCreateWinkStmt = "INSERT INTO wink (userid, fid, fname, fyrs) VALUES (?, ?, ?, ?)"
    kDeleteWinkStmt = "DELETE FROM wink WHERE userid = ? AND fid = ?"
    kReadWinksStmt  = "SELECT fid, fname, fyrs FROM wink WHERE userid = ?"
)

type CreateEdgeParams struct {
    FriendUserId   int64  `param:"fid" validate:"required"`
    FriendUsername string `param:"fname" validate:"min=2,max=40"`
    FriendYRS      int64  `param:"fyrs" validate:"required"`
    UserYRS        int64  `param:"yrs" validate:"required"`
}

/* Invite */
func (h *Handler) CreateInvite(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p CreateEdgeParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    // If the friend has already invited the user, then the friendship can be created directly
    // otherwise create an invite edge
    if h.EdgeExist(kInvite, p.FriendUserId, userid) {
        // delete the invite since the relationship is upgraded to friendship
        h.DB.Query(kDeleteInviteStmt, p.FriendUserId, userid).Exec()
        h.addFriendAndRespond(w, userid, p.FriendUserId, username, p.FriendUsername, p.UserYRS, p.FriendYRS)
        return
    }

    if err := h.DB.Query(kCreateInviteStmt, p.FriendUserId, userid, username, p.UserYRS).Exec(); err != nil {
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

    if err := h.DB.Query(kDeleteInviteStmt, userid, p.FriendUserId).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

/* Wink */
func (h *Handler) CreateWink(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p CreateEdgeParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    // If the friend has already winked the user, then the friendship can be created directly
    // otherwise create an wink edge
    if h.EdgeExist(kWink, p.FriendUserId, userid) {
        // delete the wink since the relationship is upgraded to friendship
        h.DB.Query(kDeleteWinkStmt, p.FriendUserId, userid).Exec()
        h.addFriendAndRespond(w, userid, p.FriendUserId, username, p.FriendUsername, p.UserYRS, p.FriendYRS)
        return
    }

    if err := h.DB.Query(kCreateWinkStmt, p.FriendUserId, userid, username, p.UserYRS).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

type DeleteWinkParams struct {
    FriendUserId int64 `param:"fid" validate:"required"`
}

func (h *Handler) DeleteWink(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p DeleteWinkParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    if err := h.DB.Query(kDeleteWinkStmt, userid, p.FriendUserId).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

/* Friend*/
func (h *Handler) AddFriend(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p CreateEdgeParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    h.addFriendAndRespond(w, userid, p.FriendUserId, username, p.FriendUsername, p.UserYRS, p.FriendYRS)
    return
}

type RemoveFriendParams struct {
    FriendUserId int64 `param:"fid" validate:"required"`
}

func (h *Handler) RemoveFriend(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p RemoveFriendParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    query := h.DB.Query(kRemoveFriendStmt, userid, p.FriendUserId)
    if err := query.Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    if err := query.Bind(p.FriendUserId, userid).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

func (h *Handler) ReadInvites(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    h.readEdgesAndRespond(w, kReadInvitesStmt, userid)
}

func (h *Handler) ReadWinks(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    h.readEdgesAndRespond(w, kReadWinksStmt, userid)
}

func (h *Handler) ReadFriends(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    h.readEdgesAndRespond(w, kReadFriendsStmt, userid)
}

func (h *Handler) EdgeExist(table string, src, dest int64) (exist bool) {
    format := "SELECT fid, fname, fyrs FROM %v WHERE userid = ? AND fid = ?"
    stmt := fmt.Sprintf(format, table)

    var fid int64 = 0
    if err := h.DB.Query(stmt, src, dest).Consistency(gocql.One).Scan(&fid); err != nil {
        return false
    }

    return fid > 0
}

func (h *Handler) readEdgesAndRespond(w http.ResponseWriter, stmt string, src int64) {
    iter := h.DB.Query(stmt, src).Consistency(gocql.One).Iter()
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

func (h *Handler) addFriendAndRespond(w http.ResponseWriter, userid, fid int64, username, fname string, userYRS, fYRS int64) {
    query := h.DB.Query(kAddFriendStmt, userid, fid, fname, fYRS)
    if err := query.Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    if err := query.Bind(fid, userid, username, userYRS).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}
