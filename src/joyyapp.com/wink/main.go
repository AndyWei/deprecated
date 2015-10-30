/*
 * main.go
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package main

import (
    "github.com/lidashuang/goji_gzip"
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
    authenticate := auth.JWTMiddleware

    authHandler := &auth.Handler{DB: db}
    friendshipHandler := &friendship.Handler{DB: db}
    postHandler := &post.Handler{DB: db}
    userHandler := &user.Handler{DB: db}

    router.Use(gzip.GzipHandler)

    router.Get("/v1/ping", pong)
    router.Get("/v1/auth/cognito", authenticate(authHandler.Cognito))
    router.Get("/v1/friendship", authenticate(friendshipHandler.Friendship))
    router.Get("/v1/post/timeline", authenticate(postHandler.Timeline))
    router.Get("/v1/post/userline", authenticate(postHandler.Userline))
    router.Get("/v1/post/commentline", authenticate(postHandler.Commentline))
    router.Get("/v1/user/profile", authenticate(userHandler.Profile))
    router.Get("/v1/xmpp/check_password", authHandler.CheckPassword)
    router.Get("/v1/xmpp/user_exists", authHandler.CheckExistence)

    router.Post("/v1/auth/signin", authHandler.SignIn)
    router.Post("/v1/auth/signup", authHandler.SignUp)
    router.Post("/v1/comment/create", authenticate(postHandler.CreateComment))
    router.Post("/v1/comment/delete", authenticate(postHandler.DeleteComment))
    router.Post("/v1/friendship/create", authenticate(friendshipHandler.Create))
    router.Post("/v1/friendship/delete", authenticate(friendshipHandler.Delete))
    router.Post("/v1/post/create", authenticate(postHandler.Create))
    router.Post("/v1/post/delete", authenticate(postHandler.Delete))
    router.Post("/v1/user/profile", authenticate(userHandler.SetProfile))

    router.Serve()
}

func pong(w http.ResponseWriter, r *http.Request) {
    w.Write([]byte("pong"))
}
