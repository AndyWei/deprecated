/*
 * main.go
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package main

import (
    "github.com/gin-gonic/gin"
    "joyyapp.com/wink/post"
    "joyyapp.com/wink/user"
    "runtime"
)

func main() {
    runtime.GOMAXPROCS(runtime.NumCPU())
    router := gin.New()

    // Global middleware
    router.Use(gin.Logger())
    router.Use(gin.Recovery())

    nonAuth := router.Group("/v1")
    {
        nonAuth.GET("/ping", pong)
        nonAuth.POST("/user/signin", user.Signin)
        nonAuth.POST("/user/signup", user.Signup)
        nonAuth.GET("/xmpp/check_password", user.VerifyToken)
        nonAuth.GET("/xmpp/user_exists", user.CheckExistence)
    }

    jwtAuth := router.Group("/v1")
    jwtAuth.Use(user.JwtAuthMiddleWare())
    {
        jwtAuth.GET("/post/timeline", post.GetTimeline)
        jwtAuth.GET("/user/profile", user.GetProfile)
        jwtAuth.POST("/user/profile", user.SetProfile)
    }

    router.Run(":8000")
}

func pong(c *gin.Context) {
    c.String(200, "pong")
}
