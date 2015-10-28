/*
 * post.go
 * post related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package post

import (
    "github.com/gocql/gocql"
    "net/http"
)

type Handler struct {
    DB *gocql.Session
}

func (h *Handler) GetTimeline(w http.ResponseWriter, r *http.Request, userid int64, username string) {

}

func (h *Handler) getFriendIds(userid int64) ([]int64, error) {

    var fid int64
    var fids = make([]int64, 0, 128) // an empty slice, with default capacity 128
    iter := h.DB.Query(`SELECT dest_id FROM friendship WHERE userid = ?`, userid).Consistency(gocql.One).Iter()
    for iter.Scan(&fid) {
        fids = append(fids, fid)
    }

    err := iter.Close()
    return fids, err
}
