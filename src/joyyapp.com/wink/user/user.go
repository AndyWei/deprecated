// Implementation of all user related endpoints

package user

import (
    gin "github.com/gin-gonic/gin"
    // db "joyyapp.com/wink/db"
)

func panicOnError(err error) {
    if err != nil {
        panic(err)
    }
}

func Signup(c *gin.Context) {

    // dbClient := db.SharedClient()

    // c.String(200, val)
}
