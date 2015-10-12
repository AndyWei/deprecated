package main

import (
    "fmt"
    . "joyyapp.com/wink/idgen"
)

func main() {

    err, idGenerator := SharedIdGenerator(0)
    if err != nil {
        return
    }

    err, id := idGenerator.NextId()

    if err != nil {
        return
    }

    fmt.Println("id =", id)
}
