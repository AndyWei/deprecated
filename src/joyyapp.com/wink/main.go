package main

import (
    "github.com/gin-gonic/gin"
    "joyyapp.com/wink/post"
    "joyyapp.com/wink/user"
)

func main() {

    // err, idGenerator := SharedIdGenerator(0)
    // if err != nil {
    //     return
    // }

    // err, id := idGenerator.NextId()

    // if err != nil {
    //     return
    // }

    // fmt.Println("id =", id)

    router := gin.New()

    // Global middleware
    router.Use(gin.Logger())
    router.Use(gin.Recovery())

    v1 := router.Group("/v1")
    {
        v1.GET("/ping", pong)
        v1.GET("/post/timeline", post.GetTimeline)
        v1.POST("/user/singup", user.Signup)
    }

    router.Run(":8000")
}

func panicOnError(err error) {
    if err != nil {
        panic(err)
    }
}

func pong(c *gin.Context) {
    c.String(200, "pong")
}
