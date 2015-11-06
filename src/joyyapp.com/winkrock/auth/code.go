/*
 * code.go
 * SMS code validation endpoints
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package auth

import (
    "encoding/json"
    "errors"
    twilio "github.com/carlosdp/twiliogo"
    "github.com/gocql/gocql"
    plivo "github.com/micrypt/go-plivo/plivo"
    "github.com/spf13/viper"
    . "joyyapp.com/winkrock/util"
    "math/rand"
    "net/http"
    "strconv"
    "strings"
    "time"
)

var (
    kPlivoSourceNumber  = ""
    kTwilioSourceNumber = ""

    pl  *plivo.Client        = nil
    tw  *twilio.TwilioClient = nil
)

func init() {
    rand.Seed(time.Now().UTC().UnixNano())

    viper.SetConfigName("config")
    viper.SetConfigType("toml")
    viper.AddConfigPath("/etc/winkrock/")
    err := viper.ReadInConfig()
    LogPanic(err)

    kPlivoAuthId := viper.GetString("plivo.authId")
    kPlivoAuthToken := viper.GetString("plivo.authToken")
    kPlivoSourceNumber = viper.GetString("plivo.sourceNumber")
    pl = plivo.NewClient(nil, kPlivoAuthId, kPlivoAuthToken)

    kTwilioSid := viper.GetString("plivo.authId")
    kTwilioToken := viper.GetString("plivo.authToken")
    kTwilioSourceNumber = viper.GetString("plivo.sourceNumber")
    tw = twilio.NewClient(kTwilioSid, kTwilioToken)
}

/*
 * Ask for validation code via SMS
 */
type SendCodeParams struct {
    Phone int64 `param:"phone" validate:"required"`
}

func (h *Handler) RequestCode(w http.ResponseWriter, req *http.Request) {
    var p SendCodeParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    code := random(1000, 9999)
    codestr := strconv.Itoa(code)
    phone := strconv.FormatInt(p.Phone, 10)

    if isTwilioCountry(phone) {
        _, err := twilio.NewMessage(tw, kTwilioSourceNumber, phone, twilio.Body(codestr))
        if err == nil {
            h.saveCodeAndRespond(w, p.Phone, code)
            return
        }
    }

    mp := &plivo.MessageSendParams{
        Src:  kPlivoSourceNumber,
        Dst:  phone,
        Text: codestr,
    }

    _, _, err := pl.Message.Send(mp)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    h.saveCodeAndRespond(w, p.Phone, code)
    return
}

/*
 * Validate phone number and code
 */
type ValidateCodeParams struct {
    Phone int64 `param:"phone" validate:"required"`
    Code  int   `param:"code" validate:"required"`
}

func (h *Handler) ValidateCode(w http.ResponseWriter, req *http.Request) {
    var p ValidateCodeParams
    if err := ParseAndCheck(req, &p); err != nil {
        RespondError(w, err, http.StatusBadRequest)
        return
    }

    var code int
    stmt := "SELECT code FROM code_by_phone where phone = ?"
    if err := h.DB.Query(stmt, p.Phone).Consistency(gocql.One).Scan(&code); err != nil {
        RespondError(w, err, http.StatusBadRequest)
    }

    if code != p.Code {
        RespondError(w, errors.New(ErrSmsCodeInvalid), http.StatusBadRequest)
    }

    stmt = "SELECT username FROM user_by_phone where phone = ?"
    iter := h.DB.Query(stmt, p.Phone).Consistency(gocql.One).Iter()
    usernames, err := iter.SliceMap()
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
    }

    bytes, err := json.Marshal(usernames)
    if err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondData(w, bytes)
    return
}

func (h *Handler) saveCodeAndRespond(w http.ResponseWriter, phone int64, code int) {

    if err := h.DB.Query(`INSERT INTO code_by_phone (phone, code) VALUES (?, ?)`,
        phone, code).Exec(); err != nil {
        RespondError(w, err, http.StatusBadGateway)
        return
    }

    RespondOK(w)
    return
}

// For phone numbers in China, Indonesia and UK, send SMS via twilio
func isTwilioCountry(phone string) bool {
    return strings.HasPrefix(phone, "86") || strings.HasPrefix(phone, "62") || strings.HasPrefix(phone, "44")
}

func random(min, max int) int {
    return rand.Intn(max-min) + min
}
