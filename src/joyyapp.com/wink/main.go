/*
 * main.go
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package main

import (
    router "github.com/zenazn/goji"
    "joyyapp.com/wink/auth"
    "joyyapp.com/wink/cassandra"
    "joyyapp.com/wink/friendship"
    "joyyapp.com/wink/post"
    "joyyapp.com/wink/user"
    "net/http"
    "runtime"
)

func main() {
    runtime.GOMAXPROCS(runtime.NumCPU())

    db := cassandra.DB()
    authHandler := &auth.Handler{DB: db}
    friendshipHandler := &friendship.Handler{DB: db}
    postHandler := &post.Handler{DB: db}
    userHandler := &user.Handler{DB: db}

    router.Get("/v1/ping", pong)
    router.Get("/v1/xmpp/check_password", authHandler.CheckPassword)
    router.Get("/v1/xmpp/user_exists", authHandler.CheckExistence)
    router.Post("/v1/auth/signin", authHandler.SignIn)
    router.Post("/v1/auth/signup", authHandler.SignUp)

    auth := auth.JWTMiddleware

    router.Get("/v1/auth/cognito", auth(authHandler.Cognito))
    router.Get("/v1/friendship", auth(friendshipHandler.GetAll))
    router.Post("/v1/friendship/create", auth(friendshipHandler.Create))
    router.Post("/v1/friendship/delete", auth(friendshipHandler.Delete))

    router.Get("/v1/post/timeline", auth(postHandler.Timeline))
    router.Get("/v1/post/userline", auth(postHandler.Userline))
    router.Get("/v1/post/commentline", auth(postHandler.Commentline))

    router.Post("/v1/post/create", auth(postHandler.Create))
    router.Post("/v1/post/delete", auth(postHandler.Delete))

    router.Post("/v1/comment/create", auth(postHandler.CreateComment))
    router.Post("/v1/comment/delete", auth(postHandler.DeleteComment))

    router.Get("/v1/user/profile", auth(userHandler.GetProfile))
    router.Post("/v1/user/profile", auth(userHandler.SetProfile))

    router.Serve()
}

func pong(w http.ResponseWriter, r *http.Request) {
    w.Write([]byte("pong"))
}
