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
    // "joyyapp.com/winkrock/push"
    . "joyyapp.com/winkrock/util"
    "net/http"
    "strconv"
    "strings"
)

type Handler struct {
    DB *gocql.Session
}

/*
 * Check if an username is available
 */
type CheckUsernameParams struct {
    Username string `param:"username" validate:"min=2,max=40"`
}

type CheckUsernameResponse struct {
    Username string `json:"username"`
    Exist    int    `json:"exist"`
}

func (h *Handler) CheckUsername(w http.ResponseWriter, req *http.Request) {

    var p CheckUsernameParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    var userid int64
    if err := h.DB.Query(`SELECT userid FROM user_by_name WHERE username = ? LIMIT 1`,
        p.Username).Consistency(gocql.One).Scan(&userid); err != nil {

        response := &CheckUsernameResponse{
            Username: p.Username,
            Exist:    0,
        }

        bytes, _ := json.Marshal(response)
        RespondData(w, bytes)
        return
    }

    response := &CheckUsernameResponse{
        Username: p.Username,
        Exist:    1,
    }

    bytes, _ := json.Marshal(response)
    RespondData(w, bytes)
    return
}

/*
 * Profile endpoints
 */
type WriteProfileParams struct {
    Phone     int64  `param:"phone" validate:"required"`
    YRS       int64  `param:"yrs" validate:"required"`
    Bio       string `param:"bio"`
    Boardcast bool   `param:"boardcast"`
}

func (h *Handler) WriteProfile(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    var p WriteProfileParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    if err := h.DB.Query(`INSERT INTO user (userid, phone, yrs, bio) VALUES (?, ?, ?, ?)`,
        userid, p.Phone, p.YRS, p.Bio).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    if err := h.DB.Query(`INSERT INTO user_by_phone (phone, username, userid, yrs) VALUES (?, ?, ?, ?)`,
        p.Phone, username, userid, p.YRS).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    if err := h.DB.Query(`INSERT INTO user_by_name (username, userid, yrs) VALUES (?, ?, ?)`,
        username, userid, p.YRS).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    // inform all my friends
    if p.Boardcast {
        fids, err := h.getFriendIds(userid)
        if err != nil {
            RespondError(w, err, http.StatusBadGateway)
            return
        }

        query := h.DB.Query(`INSERT INTO friend (userid, fid, fyrs) VALUES (?, ?, ?)`, 0, 0, 0)
        for _, fid := range fids {
            query.Bind(fid, userid, p.YRS).Exec()
        }
    }

    RespondOK(w)
    return
}

func (h *Handler) ReadProfile(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    m := make(map[string]interface{})

    if err := h.DB.Query(`SELECT username, phone, yrs, bio FROM user WHERE userid = ? LIMIT 1`,
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
    YRS     int64  `param:"yrs" validate:"required"`
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

type ReadUsersParams struct {
    Country  string `param:"country" validate:"alpha,len=2"`
    Sex      string `param:"sex" validate:"required"`
    Zip      string `param:"zip" validate:"required"`
    BeforeId int64  `param:"beforeid" validate:"required"`
}

func (h *Handler) ReadUsers(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    var p ReadUsersParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    ziplen := math.Min(5, len(p.Zip))
    format := "SELECT userid, username, yrs FROM user_csz%v WHERE area = ? AND month = ? AND userid < ? LIMIT 100"
    stmt := fmt.Sprintf(format, ziplen)
    area := strings.ToUpper(p.Country + p.Sex + p.Zip)
    month := ThisMonth()

    query := h.DB.Query(stmt, area, month, p.BeforeId)
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

type ReadContactsParams struct {
    Phones []int64 `param:"phone"`
}

func (h *Handler) ReadContacts(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    var p ReadContactsParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    iter := h.DB.Query(`SELECT phone, username, userid, yrs FROM user_by_phone WHERE phone IN ? `, p.Phones).Consistency(gocql.One).Iter()
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

func (h *Handler) getFriendIds(userid int64) ([]int64, error) {

    var result []int64
    var fid int64

    iter := h.DB.Query(`SELECT fid FROM friend WHERE userid = ? LIMIT 500`, userid).Consistency(gocql.One).Iter()
    for iter.Scan(&fid) {
        result = append(result, fid)
    }
    err := iter.Close()
    return result, err
}
