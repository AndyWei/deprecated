// The cassandra DB client singleton provieding config and global shared DB client instance

package db

import (
// cs "github.com/gocql/gocql"
// viper "github.com/spf13/viper"
)

// var sharedClient *cs.Client = nil

func panicOnError(err error) {
    if err != nil {
        panic(err)
    }
}

func init() {

    // viper.SetConfigName("config")
    // viper.AddConfigPath("$HOME")
    // err := viper.ReadInConfig()
    // panicOnError(err)

    // clientPolicy := cs.NewClientPolicy()
    // clientPolicy.ConnectionQueueSize = 64
    // clientPolicy.LimitConnectionsToQueueSize = true
    // clientPolicy.Timeout = 50 * time.Millisecond

    // client, err := cs.NewClientWithPolicy(clientPolicy,
    //     viper.GetString("aerospike.host"),
    //     viper.GetString("aerospike.port")
    // )
    // panicOnError(err)
}

// func SharedClient() *as.Client {
//     return sharedClient
// }
