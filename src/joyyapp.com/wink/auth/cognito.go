/*
 * cognito.go
 * AWS cognito related endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package auth

import (
    "encoding/json"
    "github.com/aws/aws-sdk-go/aws"
    "github.com/aws/aws-sdk-go/aws/session"
    cog "github.com/aws/aws-sdk-go/service/cognitoidentity"
    "github.com/spf13/viper"
    . "joyyapp.com/wink/util"
    "net/http"
    "strconv"
)

var (
    cognito                *cog.CognitoIdentity = nil
    kIdentifyPoolId        string
    kIdentifyExpiresInSecs int64
)

func init() {

    viper.SetConfigName("config")
    viper.SetConfigType("toml")
    viper.AddConfigPath("/etc/wink/")
    err := viper.ReadInConfig()
    LogPanic(err)

    kIdentifyPoolId = viper.GetString("aws.identifyPoolID")
    kIdentifyExpiresInSecs = int64(viper.GetInt("aws.identifyExpiresInSecs"))

    cognito = cog.New(session.New(), aws.NewConfig().WithRegion("us-east-1"))
}

/*
 * Get Cognito ID
 */
func (h *Handler) Cognito(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    idstr := strconv.FormatInt(userid, 10)
    params := &cog.GetOpenIdTokenForDeveloperIdentityInput{
        IdentityPoolId: aws.String(kIdentifyPoolId),
        Logins: map[string]*string{
            "joyy": aws.String(idstr),
        },
        TokenDuration: aws.Int64(kIdentifyExpiresInSecs),
    }

    resp, err := cognito.GetOpenIdTokenForDeveloperIdentity(params)

    if err != nil {
        ReplyError(w, err.Error(), http.StatusBadGateway)
        return
    }

    bytes, _ := json.Marshal(resp)
    ReplyData(w, bytes)
    return
}
