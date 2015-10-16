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
)

func main() {

    router := gin.New()

    // Global middleware
    router.Use(gin.Logger())
    router.Use(gin.Recovery())

    v1 := router.Group("/v1")
    {
        v1.GET("/ping", pong)
        v1.GET("/post/timeline", post.GetTimeline)
        v1.POST("/user/signup", user.Signup)
    }

    router.Run(":8000")
}

func pong(c *gin.Context) {
    c.String(200, "pong")
}
