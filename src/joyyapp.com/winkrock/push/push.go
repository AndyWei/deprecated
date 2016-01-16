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
    "github.com/gocql/gocql"
    "github.com/spf13/viper"
    . "joyyapp.com/winkrock/util"
    "net/http"
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
    PNS    int    `param:"pns" validate:"min=1,max=3"`
    DToken string `param:"dtoken" validate:"required"`
}

func (h *Handler) RegisterDevice(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    var p RegisterDeviceParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    arn, err := h.endpointARN(userid)
    if err != nil {
        h.registerAndRespond(w, userid, p.PNS, p.DToken)
        return
    }

    dtoken, enabled, err := getAttributes(arn)
    if err != nil {
        h.registerAndRespond(w, userid, p.PNS, p.DToken)
        return
    }

    if dtoken != p.DToken || !enabled {
        if err := setAttributes(arn, dtoken); err != nil {
            RespondError(w, err.Error(), http.StatusBadGateway)
        }
    }

    RespondOK(w)
    return
}

func (h *Handler) RemoveDevice(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    if err := h.DB.Query(`DELETE FROM user_device WHERE userid = ?`, userid).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

type PushParams struct {
    FromUserId int64  `param:"from" validate:"required"`
    ToUserId   int64  `param:"to" validate:"required"`
    Message    string `param:"message" validate:"required"`
}

func (h *Handler) Push(w http.ResponseWriter, req *http.Request) {

    var p PushParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    h.send(p.ToUserId, p.Message)

    RespondOK(w)
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

func (h *Handler) send(userid int64, message string) {

    arn, err := h.endpointARN(userid)
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
        LogInfo(err.Error())
        return
    }

    return
}

func (h *Handler) registerAndRespond(w http.ResponseWriter, userid int64, pns int, dtoken string) {
    arn, err := doRegister(pns, dtoken)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
    }

    if err := h.DB.Query(`INSERT INTO user_device (userid, pns, dtoken, arn) VALUES (?, ?, ?, ?)`,
        userid, pns, dtoken, arn).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

func (h *Handler) endpointARN(userid int64) (arn string, err error) {
    stmt := "SELECT arn FROM user_device where userid = ?"
    if err = h.DB.Query(stmt, userid).Scan(&arn); err != nil {
        return "", err
    }

    return arn, nil
}

func getAttributes(arn string) (dtoken string, enabled bool, err error) {

    params := &sns.GetEndpointAttributesInput{
        EndpointArn: aws.String(arn),
    }

    resp, err := svc.GetEndpointAttributes(params)
    if err != nil {
        return "", false, err
    }

    dtoken = *resp.Attributes["Token"]
    enabled = (*resp.Attributes["Enabled"] == "true")
    return dtoken, enabled, nil
}

func setAttributes(arn, dtoken string) (err error) {

    params := &sns.SetEndpointAttributesInput{
        Attributes: map[string]*string{
            "Enabled": aws.String("true"),
            "Token":   aws.String(dtoken),
        },
        EndpointArn: aws.String(arn),
    }
    _, err = svc.SetEndpointAttributes(params)
    return err
}

func doRegister(pns int, dtoken string) (arn string, err error) {

    appArn, err := applicationARN(pns)
    if err != nil {
        return "", err
    }

    params := &sns.CreatePlatformEndpointInput{
        PlatformApplicationArn: aws.String(appArn),
        Token: aws.String(dtoken),
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
