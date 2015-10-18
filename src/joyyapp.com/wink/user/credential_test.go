package user

import (
    "encoding/json"
    "fmt"
    "github.com/stretchr/testify/assert"
    "io/ioutil"
    "joyyapp.com/wink/cassandra"
    "net/http"
    "strings"
    "testing"
)

type SignResponse struct {
    Id    string `json: "id"`
    Token string `json: "token"`
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

func getUserIdByName(username string) (userid string, err error) {

    db := cassandra.SharedSession()
    var id int64
    err = db.Query(`SELECT id FROM user_by_name WHERE username = ? LIMIT 1`,
        username).Scan(&id)

    return string(id), err
}

func sendCheckExistenceRequest(userid, domain string) (resp *http.Response, err error) {
    // request
    endpoint := "http://localhost:8000/v1/xmpp/user_exists?user=%v&server=%v"
    url := fmt.Sprintf(endpoint, userid, domain)
    req, _ := http.NewRequest("GET", url, nil)

    // send
    return client.Do(req)
}

func TestSignup(t *testing.T) {

    assert := assert.New(t)

    resp, err := sendSignRequest("signup", "andy", "password")
    assert.Nil(err)
    assert.Equal(resp.StatusCode, http.StatusOK, "should response StatusOK")

    body, err := ioutil.ReadAll(resp.Body)
    assert.Nil(err)

    responseData := new(SignResponse)
    err = json.Unmarshal(body, responseData)
    assert.Nil(err)
    assert.NotNil(responseData.Id)
    assert.NotNil(responseData.Token)
    resp.Body.Close()

    // conflict username should be rejected
    resp, err = sendSignRequest("signup", "andy", "password")
    assert.Nil(err)
    assert.Equal(resp.StatusCode, http.StatusBadRequest, "should response StatusBadRequest for signup with existing username")

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

    assert := assert.New(t)

    resp, err := sendSignRequest("signin", "andy", "password")
    assert.Nil(err)
    assert.Equal(resp.StatusCode, http.StatusOK, "should response StatusOK")

    body, err := ioutil.ReadAll(resp.Body)
    assert.Nil(err)

    responseData := new(SignResponse)
    err = json.Unmarshal(body, responseData)
    assert.Nil(err)
    assert.NotNil(responseData.Id)
    assert.NotNil(responseData.Token)
    resp.Body.Close()

    // incorrect password should be rejected
    resp, err = sendSignRequest("signin", "andy", "wrongpassword")
    assert.Nil(err)
    assert.Equal(resp.StatusCode, http.StatusUnauthorized, "should response StatusUnauthorized for incorrect password")
}

func TestCheckExistence(t *testing.T) {

    assert := assert.New(t)

    // signup new user xxooo
    resp, err := sendSignRequest("signup", "xxooo", "password")
    assert.Nil(err)
    assert.Equal(resp.StatusCode, http.StatusOK, "should response StatusOK")

    body, err := ioutil.ReadAll(resp.Body)
    assert.Nil(err)

    responseData := new(SignResponse)
    err = json.Unmarshal(body, responseData)
    assert.Nil(err)
    assert.NotNil(responseData.Id)
    assert.NotNil(responseData.Token)
    resp.Body.Close()

    // check the existence of the new user xxooo
    userid := responseData.Id

    resp, err = sendCheckExistenceRequest(userid, "joyy.im")
    assert.Nil(err)
    assert.Equal(resp.StatusCode, http.StatusOK, "should response StatusOK")

    // non-existed user
    resp, err = sendCheckExistenceRequest("1234567", "joyy.im")
    assert.Nil(err)
    assert.Equal(resp.StatusCode, http.StatusNotFound, "should response StatusNotFound")

    // incorrect domain
    resp, err = sendCheckExistenceRequest(userid, "google.com")
    assert.Nil(err)
    assert.Equal(resp.StatusCode, http.StatusConflict, "should response StatusConflict for incorrect domain")
}
