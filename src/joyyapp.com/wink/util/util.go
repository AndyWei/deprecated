/*
 * cassandra.go
 * The collection of utility functions
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package util

import (
    "joyyapp.com/wink/idgen"
    "log"
)

func LogError(err error) {
    if err != nil {
        log.Print(err)
    }
}

func LogFatal(err error) {
    if err != nil {
        log.Fatal(err)
    }
}

func LogInfo(format string, v ...interface{}) {
    log.Printf(format, v)
}

func NewID() int64 {
    idGenerator := idgen.SharedInstance()
    err, id := idGenerator.NewId()
    PanicOnError(err)
    return id
}

func PanicOnError(err error) {
    if err != nil {
        log.Panic(err)
    }
}
