/*
 * push.go
 * push notification libary
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package push

import (
    "encoding/json"
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
    Service int    `param:"service" validate:"min=1,max=3"`
    DToken  string `param:"dtoken" validate:"required"`
}

func (h *Handler) RegisterDevice(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    var p RegisterDeviceParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    device, err := h.getDeviceRecord(userid)
    if err != nil {
        h.registerAndRespond(w, userid, p.Service, p.DToken)
        return
    }

    arn := device["arn"].(string)
    dtoken, enabled, err := getAttributes(arn)
    if err != nil {
        h.registerAndRespond(w, userid, p.Service, p.DToken)
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

type UpdateBadgeParams struct {
    Count int `param:"count" validate:"min=0"`
}

func (h *Handler) UpdateBadge(w http.ResponseWriter, req *http.Request, userid int64, username string) {

    var p UpdateBadgeParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    if err := h.DB.Query(`INSERT INTO user_device (userid, badge) VALUES (?, ?)`,
        userid, p.Count).Exec(); err != nil {
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

    var messageMap map[string]interface{}
    if err := json.Unmarshal([]byte(p.Message), &messageMap); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    h.send(p.ToUserId, messageMap["title"].(string))

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

type APS struct {
    Alert string `json:"alert"`
    Badge int    `json:"badge"`
    Sound string `json:"sound"`
}

type APNS struct {
    APS APS `json:"aps"`
}

/*
 * Note: AWS SNS need the content of APNS field is in format of string, not usual json string.
 * E.g., this is a good one:
 * {"default":"andyw: hello","APNS":"{\"aps\":{\"alert\":\"andyw: hello\",\"badge\":1,\"sound\":\"default\"}}"}
 * and this is a bad one:
 * {"default":"andyw: hello","APNS":"{"aps\":{"alert":"andyw: hello","badge":1,"sound":"default"}}"}
 *
 * So we have to use 2-step-marshals keep the '\' characters
 */
type Notification struct {
    Default string `json:"default"`
    APNS    string `json:"APNS"`
}

func (h *Handler) send(userid int64, txt string) {

    device, err := h.getDeviceRecord(userid)
    if err != nil {
        return // the receiver didn't register for receiving push notification, so do nothing
    }

    badge := device["badge"].(int) + 1
    apns := APNS{
        APS: APS{
            Alert: txt,
            Badge: badge,
            Sound: "default",
        },
    }

    bytes, _ := json.Marshal(apns)
    apnsStr := string(bytes[:])
    n := Notification{
        Default: txt,
        APNS:    apnsStr,
    }

    bytes, _ = json.Marshal(n)
    message := string(bytes[:])
    arn := device["arn"].(string)

    params := &sns.PublishInput{
        Message:          aws.String(message),
        MessageStructure: aws.String("json"),
        MessageAttributes: map[string]*sns.MessageAttributeValue{
            "Key": { // Required
                DataType:    aws.String("String"),
                StringValue: aws.String("String"),
            },
        },
        TargetArn: aws.String(arn),
    }
    _, err = svc.Publish(params)

    if err != nil {
        LogInfo(err.Error())
        return
    }

    // update badge count and ignore errors if any
    h.DB.Query(`INSERT INTO user_device (userid, badge) VALUES (?, ?)`, userid, badge).Exec()
    return
}

func (h *Handler) registerAndRespond(w http.ResponseWriter, userid int64, service int, dtoken string) {

    arn, err := doRegister(service, dtoken)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
    }

    if err := h.DB.Query(`INSERT INTO user_device (userid, service, dtoken, arn) VALUES (?, ?, ?, ?)`,
        userid, service, dtoken, arn).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

func (h *Handler) getDeviceRecord(userid int64) (device map[string]interface{}, err error) {

    device = make(map[string]interface{})
    stmt := "SELECT * FROM user_device where userid = ?"
    if err = h.DB.Query(stmt, userid).Consistency(gocql.One).MapScan(device); err != nil {
        return nil, err
    }

    return device, nil
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

func doRegister(service int, dtoken string) (arn string, err error) {

    appArn, err := applicationARN(service)
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

func applicationARN(service int) (arn string, err error) {
    err = nil
    switch service {
    case 1:
        arn = kSnsArnApns
    default:
        arn = ""
        err = errors.New(ErrPnsInvalid)
    }
    return arn, err
}
