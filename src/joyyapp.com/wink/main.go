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
    "joyyapp.com/wink/edge"
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
    edgeHandler := &edge.Handler{DB: db}
    postHandler := &post.Handler{DB: db}
    userHandler := &user.Handler{DB: db}

    router.Use(gzip.GzipHandler)

    router.Get("/v1/ping", pong)

    router.Get("/v1/auth/cognito", authenticate(authHandler.Cognito))
    router.Post("/v1/auth/signin", authHandler.SignIn)
    router.Post("/v1/auth/signup", authHandler.SignUp)

    router.Get("/v1/friendship", authenticate(edgeHandler.ReadFriendships))
    router.Post("/v1/friendship/create", authenticate(edgeHandler.CreateFriendship))
    router.Post("/v1/friendship/delete", authenticate(edgeHandler.DeleteFriendship))

    router.Get("/v1/invite", authenticate(edgeHandler.ReadInvites))
    router.Post("/v1/invite/create", authenticate(edgeHandler.CreateInvite))
    router.Post("/v1/invite/delete", authenticate(edgeHandler.DeleteInvite))

    router.Get("/v1/post/timeline", authenticate(postHandler.ReadTimeline))
    router.Get("/v1/post/userline", authenticate(postHandler.ReadUserline))
    router.Post("/v1/post/create", authenticate(postHandler.CreatePost))
    router.Post("/v1/post/delete", authenticate(postHandler.DeletePost))

    router.Get("/v1/post/commentline", authenticate(postHandler.ReadCommentline))
    router.Post("/v1/post/comment/create", authenticate(postHandler.CreateComment))
    router.Post("/v1/post/comment/delete", authenticate(postHandler.DeleteComment))

    router.Get("/v1/user/profile", authenticate(userHandler.ReadProfile))
    router.Post("/v1/user/profile", authenticate(userHandler.CreateProfile))

    router.Get("/v1/user", authenticate(userHandler.ReadUsers))
    router.Post("/v1/user/appear", authenticate(userHandler.Appear))

    router.Get("/v1/xmpp/check_password", authHandler.CheckPassword)
    router.Get("/v1/xmpp/user_exists", authHandler.CheckExistence)

    router.Serve()
}

func pong(w http.ResponseWriter, r *http.Request) {
    w.Write([]byte("pong"))
}
