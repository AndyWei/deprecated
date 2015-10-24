/*
 * main.go
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package main

import (
    "github.com/julienschmidt/httprouter"
    "joyyapp.com/wink/cassandra"
    // "joyyapp.com/wink/friendship"
    // "joyyapp.com/wink/post"
    "joyyapp.com/wink/jwt"
    "joyyapp.com/wink/user"
    . "joyyapp.com/wink/util"
    "net/http"
    "runtime"
)

func main() {
    runtime.GOMAXPROCS(runtime.NumCPU())

    router := httprouter.New()

    db := cassandra.DB()
    userHandler := &user.Handler{DB: db}

    router.GET("/v1/ping", pong)
    router.GET("/v1/xmpp/check_password", userHandler.CheckPassword)
    router.GET("/v1/xmpp/user_exists", userHandler.CheckExistence)

    router.POST("/v1/user/signin", userHandler.SignIn)
    router.POST("/v1/user/signup", userHandler.SignUp)

    auth := jwt.AuthMiddleware
    // router.GET("/v1/post/timeline", auth(p.GetTimeline))
    router.GET("/v1/user/profile", auth(userHandler.GetProfile))
    // router.GET("/v1/friendship", auth(f.GetAll))

    router.POST("/v1/user/profile", auth(userHandler.SetProfile))
    // router.POST("/v1/friendship/create", auth(f.Create))
    // router.POST("/v1/friendship/update", auth(f.Update))
    // router.POST("/v1/friendship/destroy", auth(f.Destroy)

    LogFatal(http.ListenAndServe(":8000", router))
}

func pong(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
    w.Write([]byte("pong"))
}
