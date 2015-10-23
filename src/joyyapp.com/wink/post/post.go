/*
 * post.go
 * post related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package post

import (
    "github.com/gocql/gocql"
    "github.com/julienschmidt/httprouter"
    "net/http"
)

type Handler struct {
    DB *gocql.Session
}

func (h *Handler) GetTimeline(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {

}
