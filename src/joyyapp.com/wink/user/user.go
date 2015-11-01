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
    "strconv"
    "strings"
)

type Handler struct {
    DB *gocql.Session
}

/*
 * Profile endpoints
 */
type CreateProfileParams struct {
    Phone int64  `param:"phone" validate:"required"`
    YRS   int    `param:"yrs" validate:"required"`
    Bio   string `param:"bio"`
}

func (h *Handler) CreateProfile(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    var p CreateProfileParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    if err := h.DB.Query(`INSERT INTO user (id, phone, yrs, bio) VALUES (?, ?, ?, ?)`,
        userid, p.Phone, p.YRS, p.Bio).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    if err := h.DB.Query(`INSERT INTO user_by_phone (phone, username, id) VALUES (?, ?, ?)`,
        p.Phone, username, userid).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

func (h *Handler) ReadProfile(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    m := make(map[string]interface{})

    if err := h.DB.Query(`SELECT username, phone, yrs, bio FROM user WHERE id = ? LIMIT 1`,
        userid).Consistency(gocql.One).MapScan(m); err != nil {
        RespondError(w, ErrUserNotExist, http.StatusNotFound)
        return
    }

    bytes, err := json.Marshal(m)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondData(w, bytes)
    return
}

/*
 * Appear endpoints
 */
type AppearParams struct {
    Country string `param:"country" validate:"alpha,len=2"`
    Zip     string `param:"zip" validate:"alphanum"`
    YRS     int    `param:"yrs" validate:"required"`
}

func (h *Handler) Appear(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    var p AppearParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    isLastDay := IsLastDayOfThisMonth()
    month := ThisMonth()
    sex := p.YRS & 0xff // sex is the lowest 8 bits of yrs
    sexstr := strconv.FormatInt(int64(sex), 36)

    format := "INSERT INTO user_csz%v (area, month, userid, username, yrs) VALUES (?, ?, ?, ?, ?)"
    ziplen := math.Min(5, len(p.Zip))
    for i := 1; i <= ziplen; i++ {
        stmt := fmt.Sprintf(format, i)

        zip := p.Zip[0:i]
        area := strings.ToUpper(p.Country + sexstr + zip)

        query := h.DB.Query(stmt, area, month, userid, username, p.YRS)
        if err := query.Exec(); err != nil {
            RespondError(w, err, http.StatusBadGateway)
            return
        }

        if isLastDay {
            query.Bind(area, NextMonth(), userid, username, p.YRS)
            if err := query.Exec(); err != nil {
                RespondError(w, err, http.StatusBadGateway)
                return
            }
        }
    }

    RespondOK(w)
    return
}

type UserParams struct {
    Country   string `param:"country" validate:"len=2"`
    Sex       string `param:"sex" validate:"required"`
    Zip       string `param:"zip" validate:"required"`
    MaxUserId int64  `param:"max_userid"`
}

func (h *Handler) ReadUsers(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    var p UserParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    var query *gocql.Query
    area := strings.ToUpper(p.Country + p.Sex + p.Zip)
    ziplen := math.Min(5, len(p.Zip))
    month := ThisMonth()

    if p.MaxUserId == 0 {
        format := "SELECT userid, username, yrs FROM user_csz%v WHERE area = ? AND month = ? LIMIT 100"
        stmt := fmt.Sprintf(format, ziplen)
        query = h.DB.Query(stmt, area, month)
    } else {
        format := "SELECT userid, username, yrs FROM user_csz%v WHERE area = ? AND month = ? AND userid < ? LIMIT 100"
        stmt := fmt.Sprintf(format, ziplen)
        query = h.DB.Query(stmt, area, month, p.MaxUserId)
    }

    iter := query.Consistency(gocql.One).Iter()
    users, err := iter.SliceMap()
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    bytes, err := json.Marshal(users)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondData(w, bytes)
    return
}
