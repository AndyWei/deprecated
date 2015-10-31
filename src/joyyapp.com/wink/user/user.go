/*
 * user.go
 * user related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package user

import (
    "encoding/json"
    "fmt"
    "github.com/gocql/gocql"
    "github.com/pkg/math"
    . "joyyapp.com/wink/util"
    "net/http"
    "strings"
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
        ReplyError(w, err, http.StatusBadRequest)
        return
    }

    if err := h.DB.Query(`INSERT INTO user (id, phone, region, sex, yob, bio) VALUES (?, ?, ?, ?, ?, ?)`,
        userid, r.Phone, r.Region, r.Sex, r.Yob, r.Bio).Exec(); err != nil {
        ReplyError(w, err, http.StatusBadGateway)
        return
    }

    if err := h.DB.Query(`INSERT INTO user_by_phone (phone, username, id) VALUES (?, ?, ?)`,
        r.Phone, username, userid).Exec(); err != nil {
        ReplyError(w, err, http.StatusBadGateway)
        return
    }

    ReplyOK(w)
    return
}

func (h *Handler) Profile(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    m := make(map[string]interface{})

    if err := h.DB.Query(`SELECT username, phone, region, sex, yob, bio FROM user WHERE id = ? LIMIT 1`,
        userid).Consistency(gocql.One).MapScan(m); err != nil {
        ReplyError(w, ErrUserNotExist, http.StatusNotFound)
        return
    }

    bytes, err := json.Marshal(m)
    if err != nil {
        ReplyError(w, err, http.StatusBadGateway)
        return
    }

    ReplyData(w, bytes)
    return
}

/*
 * Occur endpoints
 */
type OccurRequest struct {
    Country string `param:"country" validate:"alpha,len=2"`
    Sex     string `param:"sex" validate:"alpha,len=1"`
    Zip     string `param:"zip" validate:"alphanum"`
    Region  int    `param:"region" validate:"min=0,max=2"`
    Yob     int    `param:"yob" validate:"min=1900,max=2005"`
}

func (h *Handler) Occur(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    var r OccurRequest
    if err := ParseAndCheck(req, &r); err != nil {
        ReplyError(w, err, http.StatusBadRequest)
        return
    }

    isLastDay := IsLastDayOfThisMonth()
    month := ThisMonth()

    format := "INSERT INTO user_csz%v (area, month, userid, username, region, yob) VALUES (?, ?, ?, ?, ?, ?)"
    ziplen := math.Min(5, len(r.Zip))
    for i := 1; i <= ziplen; i++ {
        stmt := fmt.Sprintf(format, i)

        zip := r.Zip[0:i]
        area := strings.ToUpper(r.Country + r.Sex + zip)

        query := h.DB.Query(stmt, area, month, userid, username, r.Region, r.Yob)
        if err := query.Exec(); err != nil {
            ReplyError(w, err, http.StatusBadGateway)
            return
        }

        if isLastDay {
            query.Bind(area, NextMonth(), userid, username, r.Region, r.Yob)
            if err := query.Exec(); err != nil {
                ReplyError(w, err, http.StatusBadGateway)
                return
            }
        }
    }

    ReplyOK(w)
    return
}

type NearbyRequest struct {
    Country   string `param:"country" validate:"len=2"`
    Sex       string `param:"sex" validate:"len=1"`
    Zip       string `param:"zip" validate:"required"`
    MaxUserid int64  `param:"max_userid"`
}

func (h *Handler) Nearby(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    var r NearbyRequest
    if err := ParseAndCheck(req, &r); err != nil {
        ReplyError(w, err, http.StatusBadRequest)
        return
    }

    var query *gocql.Query
    area := strings.ToUpper(r.Country + r.Sex + r.Zip)
    ziplen := math.Min(5, len(r.Zip))
    month := ThisMonth()

    if r.MaxUserid == 0 {
        format := "SELECT userid, username, region, yob FROM user_csz%v WHERE area = ? AND month = ? LIMIT 50"
        stmt := fmt.Sprintf(format, ziplen)
        query = h.DB.Query(stmt, area, month)
        // LogInfof("Nearby query = %v", query.String())
    } else {
        format := "SELECT userid, username, region, yob FROM user_csz%v WHERE area = ? AND month = ? AND userid < ? LIMIT 50"
        stmt := fmt.Sprintf(format, ziplen)
        query = h.DB.Query(stmt, area, month, r.MaxUserid)
        // LogInfof("maxuserid Nearby query = %v", query.String())
    }

    iter := query.Consistency(gocql.One).Iter()
    users, err := iter.SliceMap()
    if err != nil {
        ReplyError(w, err, http.StatusBadGateway)
        return
    }

    bytes, err := json.Marshal(users)
    if err != nil {
        ReplyError(w, err, http.StatusBadGateway)
        return
    }

    ReplyData(w, bytes)
    return
}
