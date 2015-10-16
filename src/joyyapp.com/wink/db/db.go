// The global cassandra DB session singleton

package db

import (
    gocql "github.com/gocql/gocql"
    viper "github.com/spf13/viper"
)

var sharedSession *gocql.Session = nil

func panicOnError(err error) {
    if err != nil {
        panic(err)
    }
}

func init() {

    viper.SetConfigName("config")
    viper.SetConfigType("toml")
    viper.AddConfigPath("../")
    err := viper.ReadInConfig()
    panicOnError(err)

    hosts := viper.GetStringSlice("cassandra.hosts")
    keyspace := viper.GetString("cassandra.keyspace")
    username := viper.GetString("cassandra.username")
    password := viper.GetString("cassandra.password")

    cluster := gocql.NewCluster(hosts)
    cluster.Keyspace = keyspace
    cluster.Consistency = gocql.Quorum
    cluster.Authenticator = gocql.PasswordAuthenticator{
        Username: username,
        Password: password,
    }

    sharedSession, err := cluster.CreateSession()
    panicOnError(err)
}

func SharedSession() *gocql.Session {
    return sharedSession
}
