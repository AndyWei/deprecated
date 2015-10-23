/*
 * cassandra.go
 * The global cassandra DB session singleton
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package cassandra

import (
    "github.com/gocql/gocql"
    . "github.com/spf13/viper"
    . "joyyapp.com/wink/util"
)

var sharedDB *gocql.Session = nil

func init() {

    SetConfigName("config")
    SetConfigType("toml")
    AddConfigPath("/etc/wink/")
    err := ReadInConfig()
    PanicOnError(err)

    hosts := GetStringSlice("cassandra.hosts")
    keyspace := GetString("cassandra.keyspace")
    username := GetString("cassandra.username")
    password := GetString("cassandra.password")

    cluster := gocql.NewCluster(hosts...)
    cluster.Authenticator = gocql.PasswordAuthenticator{
        Username: username,
        Password: password,
    }
    cluster.DiscoverHosts = true
    cluster.Keyspace = keyspace
    cluster.RetryPolicy = &gocql.SimpleRetryPolicy{NumRetries: 3}

    session, err := cluster.CreateSession()
    sharedDB = session
    PanicOnError(err)
}

func DB() *gocql.Session {
    return sharedDB
}
