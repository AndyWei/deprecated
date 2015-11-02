/*
 * push.go
 * push notification libary
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package push

import (
    "errors"
    "github.com/aws/aws-sdk-go/aws"
    "github.com/aws/aws-sdk-go/aws/session"
    "github.com/aws/aws-sdk-go/service/sns"
    "github.com/spf13/viper"
    "joyyapp.com/winkrock/cassandra"
    . "joyyapp.com/winkrock/util"
)

type Handler struct {
    DB *gocql.Session
}

var (
    svc         *sns.SNS = nil
    kSnsArnApns string
)

/*
 * Device endpoints
 */
type RegisterDeviceParams struct {
    PNS   int    `param:"pns" validate:"min=1,max=3"`
    Token string `param:"token" validate:"required"`
}

func (h *Handler) RegisterDevice(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    var p RegisterDeviceParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    arn, err := endpointARN()
    if err != nil {
        doRegisterDeviceAtSNS
    }

    arn, err := RegisterDeviceAtSNS(p.PNS, p.Token)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
    }

    if err := h.DB.Query(`INSERT INTO user (id, pns, token, arn) VALUES (?, ?, ?, ?)`,
        userid, p.PNS, p.Token, arn).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

func Send(userid int64, message string) {

    arn, err := endpointARN(userid)
    if err != nil {
        return // the receiver didn't register for receiving push notification, so do nothing
    }

    params := &sns.PublishInput{
        Message: aws.String(message),
        MessageAttributes: map[string]*sns.MessageAttributeValue{
            "Key": { // Required
                DataType:    aws.String("String"), // Required
                BinaryValue: []byte("PAYLOAD"),
                StringValue: aws.String("String"),
            },
            // More values...
        },
        TargetArn: aws.String(arn),
    }
    _, err = svc.Publish(params)

    if err != nil {
        LogError(err)
        return
    }

    return
}

func init() {

    viper.SetConfigName("config")
    viper.SetConfigType("toml")
    viper.AddConfigPath("/etc/winkrock/")
    err := viper.ReadInConfig()
    LogPanic(err)

    kSnsArnApns = viper.GetString("aws.snsArnApns")

    svc = sns.New(session.New(), aws.NewConfig().WithRegion("us-east-1"))
}

func doRegisterDeviceAtSNS(pns int, token string) (arn string, err error) {

    appArn, err := applicationARN(pns)
    if err != nil {
        return "", err
    }

    params := &sns.CreatePlatformEndpointInput{
        PlatformApplicationArn: aws.String(appArn),
        Token: aws.String(token),
        Attributes: map[string]*string{
            "Enabled": aws.String("true"),
        },
    }

    resp, err := svc.CreatePlatformEndpoint(params)
    if err != nil {
        return "", err
    }

    return *resp.EndpointArn, nil
}

func applicationARN(pns int) (arn string, err error) {
    err = nil
    switch pns {
    case 1:
        arn = kSnsArnApns
    default:
        arn = ""
        err = errors.New(ErrPnsInvalid)
    }
    return arn, err
}

func endpointARN(userid int64) (arn string, err error) {
    stmt := "SELECT arn FROM user where id = ?"
    if err = cassandra.DB().Query(stmt, userid).Scan(&arn); err != nil {
        return "", err
    }

    return arn, nil
}
