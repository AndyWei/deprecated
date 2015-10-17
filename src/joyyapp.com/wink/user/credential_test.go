package user

import (
    "encoding/json"
    "io/ioutil"
    "net/http"
    "strings"
    "testing"
)

type SignResponse struct {
    Id    int64  `json:"id"`
    Token string `json:"token"`
}

var client *http.Client = nil

func init() {
    client = &http.Client{}
}

func createCredentialJson(username, password string) *CredentialJson {
    return &CredentialJson{username, password}
}

func sendSignRequest(method, username, password string) (resp *http.Response, err error) {

    // payload
    credential := createCredentialJson(username, password)
    jsondata, _ := json.Marshal(credential)
    post_data := strings.NewReader(string(jsondata))

    // request
    s := []string{"http://localhost:8000/v1/user", method}
    url := strings.Join(s, "/")
    req, _ := http.NewRequest("POST", url, post_data)
    req.Header.Set("Content-Type", "application/json")

    // send
    return client.Do(req)
}

func TestSignup(t *testing.T) {

    resp, err := sendSignRequest("signup", "andy", "password")
    if err != nil {
        t.Fatalf("Fail to send signup request. error = %v", err)
    }

    if resp.StatusCode != http.StatusOK {
        t.Errorf("Fail to response http.StatusOK. Actual resp.StatusCode = %d", resp.StatusCode)
    }

    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        t.Fatalf("Fail to read signup response. error = %v", err)
    }

    responseData := new(SignResponse)
    err = json.Unmarshal(body, responseData)
    if err != nil {
        t.Fatalf("Fail to decode signup response. error = %v", err)
    }
    resp.Body.Close()

    // conflict username should be rejected
    resp, err = sendSignRequest("signup", "andy", "password")
    if err != nil {
        t.Fatalf("Fail to resend signup response. error = %v", err)
    }

    if resp.StatusCode != http.StatusBadRequest {
        t.Errorf("Fail to response http.StatusBadRequest. Actual resp.StatusCode = %d", resp.StatusCode)
    }

    // Convey("Should be able to be authorized", func() {
    //     token := responseData.Token
    //     req, _ := http.NewRequest("GET", "http://localhost:3000/api/auth/testAuth", nil)
    //     req.Header.Set("Authorization", "Bearer "+token)
    //     client = &http.Client{}
    //     res, _ := client.Do(req)
    //     So(res.StatusCode, ShouldEqual, 200)
    // })
}

func TestSignin(t *testing.T) {

    resp, err := sendSignRequest("signin", "andy", "password")
    if err != nil {
        t.Fatalf("Fail to send signin request. error = %v", err)
    }

    if resp.StatusCode != http.StatusOK {
        t.Errorf("Fail to response http.StatusOK. Actual resp.StatusCode = %d", resp.StatusCode)
    }

    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        t.Fatalf("Fail to read signin response. error = %v", err)
    }

    responseData := new(SignResponse)
    err = json.Unmarshal(body, responseData)
    if err != nil {
        t.Fatalf("Fail to decode signin response. error = %v", err)
    }
    resp.Body.Close()

    // incorrect password should be rejected
    resp, err = sendSignRequest("signin", "andy", "wrongpassword")
    if err != nil {
        t.Fatalf("Fail to resend signin response. error = %v", err)
    }

    if resp.StatusCode != http.StatusUnauthorized {
        t.Errorf("Fail to response http.StatusUnauthorized. Actual resp.StatusCode = %d", resp.StatusCode)
    }
}
