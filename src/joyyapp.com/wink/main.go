/*
 * main.go
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package main

import (
    router "github.com/zenazn/goji"
    "joyyapp.com/wink/cassandra"
    // "joyyapp.com/wink/friendship"
    // "joyyapp.com/wink/post"
    "joyyapp.com/wink/auth"
    "joyyapp.com/wink/user"
    "net/http"
    "runtime"
)

func main() {
    runtime.GOMAXPROCS(runtime.NumCPU())

    db := cassandra.DB()
    authHandler := &auth.Handler{DB: db}
    userHandler := &user.Handler{DB: db}

    router.Get("/v1/ping", pong)
    router.Get("/v1/xmpp/check_password", authHandler.CheckPassword)
    router.Get("/v1/xmpp/user_exists", authHandler.CheckExistence)
    router.Post("/v1/auth/signin", authHandler.SignIn)
    router.Post("/v1/auth/signup", authHandler.SignUp)

    auth := auth.JWTMiddleware
    // router.Get("/v1/post/timeline", auth(p.GetTimeline))
    router.Get("/v1/user/profile", auth(userHandler.GetProfile))
    // router.Get("/v1/friendship", auth(f.GetAll))

    router.Post("/v1/user/profile", auth(userHandler.SetProfile))
    // router.Post("/v1/friendship/create", auth(f.Create))
    // router.Post("/v1/friendship/update", auth(f.Update))
    // router.Post("/v1/friendship/destroy", auth(f.Destroy)

    router.Serve()
}

func pong(w http.ResponseWriter, r *http.Request) {
    w.Write([]byte("pong"))
}
