/*
 * cache.go
 * The global redis client singleton
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package cache

import (
    . "github.com/garyburd/redigo/redis"
    . "github.com/spf13/viper"
    . "joyyapp.com/wink/util"
    "strconv"
    "time"
)

type Store struct {
    Key string
    Ttl int
}

type User struct {
    Id       int64  `redis:"i" json:"id"`
    Username string `redis:"n" json:"username"`
    Region   int    `redis:"a" json:"region"`
    Sex      int    `redis:"s" json:"sex"`
    Yob      int    `redis:"y" json:"yob"`
}

var sharedPool *Pool = nil
var UserStore *Store = &Store{"user", 7200}

func init() {

    SetConfigName("config")
    SetConfigType("toml")
    AddConfigPath("/etc/wink/")
    err := ReadInConfig()
    PanicOnError(err)

    server := GetString("redis.server")
    password := GetString("redis.password")
    maxIdle := GetInt("redis.max_idle")
    idleTimeoutInSecs := GetInt("redis.idle_timeout_in_secs")

    sharedPool = &Pool{
        MaxIdle:     maxIdle,
        IdleTimeout: time.Duration(idleTimeoutInSecs) * time.Second,
        Dial: func() (Conn, error) {
            c, err := Dial("tcp", server)
            if err != nil {
                return nil, err
            }
            if _, err := c.Do("AUTH", password); err != nil {
                c.Close()
                return nil, err
            }
            return c, err
        },
        TestOnBorrow: func(c Conn, t time.Time) error {
            _, err := c.Do("PING")
            return err
        },
    }
}

func makeKey(pk, lk string) string {
    return pk + ":" + lk
}

func SetUserStruct(user *User) error {

    conn := sharedPool.Get()
    defer conn.Close()

    idString36 := strconv.FormatInt(user.Id, 36)
    key := makeKey(UserStore.Key, idString36)

    conn.Send("HMSET", Args{}.Add(key).AddFlat(user)...)
    conn.Send("EXPIRE", key, UserStore.Ttl)
    err := conn.Flush()
    if err != nil {
        LogError(err)
        return err
    }

    _, err = conn.Receive()
    LogError(err)
    return err
}

func GetUserStruct(id interface{}) (*User, error) {

    var idInt64 int64

    switch id := id.(type) {
    case int64:
        idInt64 = id
    case string:
        idInt64, _ = strconv.ParseInt(id, 10, 64)
    }

    idString36 := strconv.FormatInt(idInt64, 36)
    key := makeKey(UserStore.Key, idString36)

    conn := sharedPool.Get()
    defer conn.Close()

    value, err := Values(conn.Do("HGETALL", key))
    if err != nil {
        LogError(err)
        return nil, err
    }

    var u User
    err = ScanStruct(value, &u)
    return &u, err
}
