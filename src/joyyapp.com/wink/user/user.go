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
    "github.com/julienschmidt/httprouter"
    . "github.com/mholt/binding"
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
    Phone  int64
    Region int
    Sex    int
    Yob    int
    Bio    string
}

func (r *UpdateProileRequest) FieldMap(req *http.Request) FieldMap {
    return FieldMap{
        &r.Phone:  Field{Form: "phone", Required: true},
        &r.Region: Field{Form: "region", Required: true},
        &r.Sex:    Field{Form: "sex", Required: true},
        &r.Yob:    Field{Form: "yob", Required: true},
        &r.Bio:    Field{Form: "bio", Required: false},
    }
}

func (r UpdateProileRequest) Validate(req *http.Request, errs Errors) Errors {

    if r.Region > 2 {
        errs.Add([]string{"region"}, "ComplaintError", ErrRegionInvalid)
    }

    if r.Sex > 2 {
        errs.Add([]string{"region"}, "ComplaintError", ErrSexInvalid)
    }

    if r.Yob < 1900 || r.Yob > 2010 {
        errs.Add([]string{"yob"}, "ComplaintError", ErrYobInvalid)
    }
    return errs
}

func (h *Handler) SetProfile(w http.ResponseWriter, req *http.Request, ps httprouter.Params) {

    userid, username, err := Parse(ps)
    if err != nil {
        ReplyError(w, err.Error(), http.StatusUnauthorized)
    }

    r := new(UpdateProileRequest)
    if Bind(req, r).Handle(w) {
        return
    }

    if err := h.DB.Query(`UPDATE user SET phone = ?, region = ?, sex = ?, yob = ?, bio = ? WHERE id = ?`,
        r.Phone, r.Region, r.Sex, r.Yob, r.Bio, userid).Exec(); err != nil {
        LogError(err)
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    if err := h.DB.Query(`INSERT INTO user_by_phone (phone, username, id) VALUES (?, ?, ?)`,
        r.Phone, username, userid).Exec(); err != nil {
        LogError(err)
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    ReplyOK(w)
    return
}

func (h *Handler) GetProfile(w http.ResponseWriter, req *http.Request, ps httprouter.Params) {

    userid, _, err := Parse(ps)
    if err != nil {
        ReplyError(w, err.Error(), http.StatusUnauthorized)
    }

    m := make(map[string]interface{})
    if err := h.DB.Query(`SELECT username, deleted, phone, region, sex, yob, bio FROM user WHERE id = ? LIMIT 1`,
        userid).Consistency(gocql.One).MapScan(m); err != nil {
        LogError(err)
        ReplyError(w, ErrUserNotExist, http.StatusNotFound)
        return
    }

    body, err := json.Marshal(m)
    if err != nil {
        LogError(err)
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    ReplyData(w, body)
    return
}
