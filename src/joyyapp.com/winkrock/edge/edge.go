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
    "joyyapp.com/winkrock/idgen"
    . "joyyapp.com/winkrock/util"
    "net/http"
)

type Handler struct {
    DB *gocql.Session
}

const (
    kFriend           = "friend"
    kCreateFriendStmt = "INSERT INTO friend (userid, fid, fname, fyrs) VALUES (?, ?, ?, ?)"
    kDeleteFriendStmt = "DELETE FROM friend WHERE userid = ? AND fid = ?"
    kReadFriendsStmt  = "SELECT fid, fname, fyrs FROM friend WHERE userid = ?"

    kInvite                    = "invite"
    kCreateInviteStmt          = "INSERT INTO invite (fromid, toid) VALUES (?, ?)"
    kDeleteInviteStmt          = "DELETE FROM invite WHERE fromid = ? AND toid = ?"
    kWriteInviteInboxStmt      = "INSERT INTO invite_inbox (userid, id, fid, fname, fyrs, phone) VALUES (?, ?, ?, ?, ?, ?)"
    kDeleteInviteInboxItemStmt = "DELETE FROM invite_inbox WHERE userid = ? AND id = ?"
    kReadInviteInboxStmt       = "SELECT * FROM invite_inbox WHERE userid = ? AND id > ? AND id < ? ORDER BY id DESC LIMIT 500"

    kWink                    = "wink"
    kCreateWinkStmt          = "INSERT INTO wink (fromid, toid) VALUES (?, ?)"
    kDeleteWinkStmt          = "DELETE FROM wink WHERE fromid = ? AND toid = ?"
    kWriteWinkInboxStmt      = "INSERT INTO wink_inbox (userid, id, fid, fname, fyrs) VALUES (?, ?, ?, ?, ?)"
    kDeleteWinkInboxItemStmt = "DELETE FROM wink_inbox WHERE userid = ? AND id = ?"
    kReadWinkInboxStmt       = "SELECT * FROM wink_inbox WHERE userid = ? AND id > ? AND id < ? ORDER BY id DESC LIMIT 500"
)

type CreateInviteParams struct {
    Fid   int64  `param:"fid" validate:"required"`
    Fname string `param:"fname" validate:"min=2,max=40"`
    Fyrs  int64  `param:"fyrs" validate:"required"`
    YRS   int64  `param:"yrs" validate:"required"`
    Phone int64  `param:"phone" validate:"required"`
}

/* Invite */
func (h *Handler) CreateInvite(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p CreateInviteParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    // If the friend has already invited the user, then the friendship can be created directly
    // otherwise create an invite edge
    if h.EdgeExist(kInvite, p.Fid, userid) {
        // delete the invite since the relationship is upgraded to friendship
        h.DB.Query(kDeleteInviteStmt, p.Fid, userid).Exec()
        h.addFriendAndRespond(w, userid, p.Fid, username, p.Fname, p.YRS, p.Fyrs)
        return
    }

    // create invite entity
    if err := h.DB.Query(kCreateInviteStmt, userid, p.Fid).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    inviteid := idgen.NewID()
    // write to the friend's invite inbox
    if err := h.DB.Query(kWriteInviteInboxStmt, p.Fid, inviteid, userid, username, p.YRS, p.Phone).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

// type DeleteInviteParams struct {
//     Fid int64 `param:"fid" validate:"required"`
// }

// func (h *Handler) DeleteInvite(w http.ResponseWriter, req *http.Request, userid int64, username string) {
//     var p DeleteInviteParams
//     if err := ParseAndCheck(req, &p); err != nil {
//         RespondError(w, err, http.StatusBadRequest)
//         return
//     }

//     if err := h.DB.Query(kDeleteInviteStmt, userid, p.Fid).Exec(); err != nil {
//         RespondError(w, err, http.StatusBadGateway)
//         return
//     }

//     RespondOK(w)
//     return
// }

type CreateWinkParams struct {
    Fid   int64  `param:"fid" validate:"required"`
    Fname string `param:"fname" validate:"min=2,max=40"`
    Fyrs  int64  `param:"fyrs" validate:"required"`
    YRS   int64  `param:"yrs" validate:"required"`
}

/* Wink */
func (h *Handler) CreateWink(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p CreateWinkParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    // If the friend has already winked the user, then the friendship can be created directly
    // otherwise create an wink edge
    if h.EdgeExist(kWink, p.Fid, userid) {
        // delete the wink since the relationship is upgraded to friendship
        h.DB.Query(kDeleteWinkStmt, p.Fid, userid).Exec()
        h.addFriendAndRespond(w, userid, p.Fid, username, p.Fname, p.YRS, p.Fyrs)
        return
    }

    if err := h.DB.Query(kCreateWinkStmt, userid, p.Fid).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    winkid := idgen.NewID()
    if err := h.DB.Query(kWriteWinkInboxStmt, p.Fid, winkid, userid, username, p.YRS).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

// type DeleteWinkParams struct {
//     Fid int64 `param:"fid" validate:"required"`
// }

// func (h *Handler) DeleteWink(w http.ResponseWriter, req *http.Request, userid int64, username string) {
//     var p DeleteWinkParams
//     if err := ParseAndCheck(req, &p); err != nil {
//         RespondError(w, err, http.StatusBadRequest)
//         return
//     }

//     if err := h.DB.Query(kDeleteWinkStmt, userid, p.Fid).Exec(); err != nil {
//         RespondError(w, err, http.StatusBadGateway)
//         return
//     }

//     RespondOK(w)
//     return
// }

/* Friend*/

type CreateFriendParams struct {
    InitiateId int64  `param:"id" validate:"required"`
    Fid        int64  `param:"fid" validate:"required"`
    Fname      string `param:"fname" validate:"min=2,max=40"`
    Fyrs       int64  `param:"fyrs" validate:"required"`
    YRS        int64  `param:"yrs" validate:"required"`
}

func (h *Handler) AcceptInvite(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p CreateFriendParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    query := h.DB.Query(kDeleteInviteStmt, p.Fid, userid)
    if err := query.Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    query = h.DB.Query(kDeleteInviteInboxItemStmt, userid, p.InitiateId)
    if err := query.Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    h.addFriendAndRespond(w, userid, p.Fid, username, p.Fname, p.YRS, p.Fyrs)
    return
}

func (h *Handler) AcceptWink(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p CreateFriendParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    query := h.DB.Query(kDeleteWinkStmt, p.Fid, userid)
    if err := query.Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    query = h.DB.Query(kDeleteWinkInboxItemStmt, userid, p.InitiateId)
    if err := query.Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    h.addFriendAndRespond(w, userid, p.Fid, username, p.Fname, p.YRS, p.Fyrs)
    return
}

type DeleteFriendParams struct {
    Fid int64 `param:"fid" validate:"required"`
}

func (h *Handler) DeleteFriend(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p DeleteFriendParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    query := h.DB.Query(kDeleteFriendStmt, userid, p.Fid)
    if err := query.Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    if err := query.Bind(p.Fid, userid).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

type ReadInboxParams struct {
    SinceId  int64 `param:"sinceid"`
    BeforeId int64 `param:"beforeid"`
}

func (h *Handler) ReadInvites(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p ReadInboxParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    h.readInboxAndRespond(w, kReadInviteInboxStmt, userid, p.SinceId, p.BeforeId)
}

func (h *Handler) ReadWinks(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    var p ReadInboxParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    h.readInboxAndRespond(w, kReadWinkInboxStmt, userid, p.SinceId, p.BeforeId)
}

func (h *Handler) ReadFriends(w http.ResponseWriter, req *http.Request, userid int64, username string) {
    iter := h.DB.Query(kReadFriendsStmt, userid).Consistency(gocql.One).Iter()
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

func (h *Handler) EdgeExist(table string, src, dest int64) (exist bool) {
    format := "SELECT toid FROM %v WHERE fromid = ? AND toid = ?"
    stmt := fmt.Sprintf(format, table)

    var toid int64 = 0
    if err := h.DB.Query(stmt, src, dest).Consistency(gocql.One).Scan(&toid); err != nil {
        return false
    }

    return toid > 0
}

func (h *Handler) readInboxAndRespond(w http.ResponseWriter, stmt string, userid, sinceId, beforeId int64) {
    iter := h.DB.Query(stmt, userid, sinceId, beforeId).Consistency(gocql.One).Iter()
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

type AddFriendResponse struct {
    Fid   int64  `json:"fid"`
    Fname string `json:"fname"`
    Fyrs  int64  `json:"fyrs"`
}

func (h *Handler) addFriendAndRespond(w http.ResponseWriter, userid, fid int64, username, fname string, userYRS, fYRS int64) {
    query := h.DB.Query(kCreateFriendStmt, userid, fid, fname, fYRS)
    if err := query.Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    if err := query.Bind(fid, userid, username, userYRS).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    response := &AddFriendResponse{
        Fid:   fid,
        Fname: fname,
        Fyrs:  fYRS,
    }

    bytes, _ := json.Marshal(response)
    RespondData(w, bytes)
    return
}
