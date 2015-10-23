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

    // nonAuth := router.Group("/v1")
    // {
    //     nonAuth.GET("/ping", pong)
    //     nonAuth.POST("/user/signin", u.SignIn)
    //     nonAuth.POST("/user/signup", u.SignUp)
    //     nonAuth.GET("/xmpp/check_password", u.CheckPassword)
    //     nonAuth.GET("/xmpp/user_exists", u.CheckExistence)
    // }

    // jwtAuth := router.Group("/v1")
    // jwtAuth.Use(user.JwtAuthMiddleWare())
    // {
    //     jwtAuth.GET("/post/timeline", p.GetTimeline)
    //     jwtAuth.GET("/user/profile", u.GetProfile)
    //     jwtAuth.POST("/user/profile", u.SetProfile)
    //     jwtAuth.GET("/friendship", f.GetAll)
    //     jwtAuth.POST("/friendship/create", f.Create)
    //     jwtAuth.POST("/friendship/update", f.Update)
    //     jwtAuth.POST("/friendship/destroy", f.Destroy)
    // }

    LogFatal(http.ListenAndServe(":8000", router))
}

func pong(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
    w.Write([]byte("pong"))
}
