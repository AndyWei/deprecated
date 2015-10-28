/*
 * user.go
 * user related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package user

import (
    "encoding/json"
    "github.com/gocql/gocql"
    . "joyyapp.com/wink/util"
    "net/http"
)

type Handler struct {
    DB *gocql.Session
}

/*
 * Profile endpoints
 */
type UpdateProileRequest struct {
    Phone  int64  `param:"phone" validate:"required"`
    Region int    `param:"region" validate:"min=0,max=2"`
    Sex    int    `param:"sex" validate:"min=0,max=2"`
    Yob    int    `param:"yob" validate:"min=1900,max=2005"`
    Bio    string `param:"bio"`
}

func (h *Handler) SetProfile(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    var r UpdateProileRequest
    if err := ParseAndCheck(req, &r); err != nil {
        ReplyError(w, err.Error(), http.StatusBadRequest)
        return
    }

    if err := h.DB.Query(`INSERT INTO user (id, phone, region, sex, yob, bio) VALUES (?, ?, ?, ?, ?, ?)`,
        userid, r.Phone, r.Region, r.Sex, r.Yob, r.Bio).Exec(); err != nil {
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    if err := h.DB.Query(`INSERT INTO user_by_phone (phone, username, id) VALUES (?, ?, ?)`,
        r.Phone, username, userid).Exec(); err != nil {
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    ReplyOK(w)
    return
}

func (h *Handler) GetProfile(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    m := make(map[string]interface{})

    if err := h.DB.Query(`SELECT username, phone, region, sex, yob, bio FROM user WHERE id = ? LIMIT 1`,
        userid).Consistency(gocql.One).MapScan(m); err != nil {
        ReplyError(w, ErrUserNotExist, http.StatusNotFound)
        return
    }

    bytes, err := json.Marshal(m)
    if err != nil {
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    ReplyData(w, bytes)
    return
}
