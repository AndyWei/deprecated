/*
 * cassandra.go
 * The global cassandra DB session
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

func DB() *gocql.Session {
    return sharedDB
}

func init() {

    SetConfigName("config")
    SetConfigType("toml")
    AddConfigPath("/etc/wink/")
    err := ReadInConfig()
    LogFatal(err)

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
    LogFatal(err)
}
