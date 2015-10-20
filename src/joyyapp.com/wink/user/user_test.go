package user

import (
    "encoding/json"
    "github.com/stretchr/testify/assert"
    "io/ioutil"
    "joyyapp.com/wink/cache"
    "net/http"
    "strconv"
    "strings"
    "testing"
)

type SetResponse struct {
    Updated string `json:"updated"`
}

func createProfileJson(phone int64, yob, region, sex int, bio string) *ProfileJson {
    return &ProfileJson{phone, region, sex, yob, bio}
}

func TestSetProfile(t *testing.T) {

    assert := assert.New(t)
    dummyUsername := "dummy_for_set"

    idString, tokenString := signup(dummyUsername, "profile")

    // payload
    profile := createProfileJson(14257850318, 1995, 0, 1, "let's make a miracle")
    jsondata, _ := json.Marshal(profile)
    post_data := strings.NewReader(string(jsondata))

    // request
    url := "http://localhost:8000/v1/user/profile"
    req, _ := http.NewRequest("POST", url, post_data)
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("Authorization", "Bearer "+tokenString)

    // send
    resp, err := client.Do(req)
    assert.Nil(err)

    // check response
    assert.Equal(http.StatusOK, resp.StatusCode, "should response StatusOK")
    body, err := ioutil.ReadAll(resp.Body)
    defer resp.Body.Close()
    assert.Nil(err)

    responseData := new(SetResponse)
    err = json.Unmarshal(body, responseData)
    assert.Nil(err)
    assert.NotNil(responseData.Updated)
    assert.Equal("user/profile", responseData.Updated, "should contain endpoint name in response")

    // check cache
    u, err := cache.GetUserStruct(idString)
    assert.Nil(err)
    assert.Equal(dummyUsername, u.Username, "should store correct username in cache")
    id, _ := strconv.ParseInt(idString, 10, 64)
    assert.Equal(id, u.Id, "should store correct userid in cache")
}

func TestGetProfile(t *testing.T) {

    assert := assert.New(t)

    dummyUsername := "dummy_for_get"
    idString, tokenString := signup(dummyUsername, "profile")

    // set profile first
    phone := int64(14008009000)
    region := 1
    sex := 2
    yob := 1990

    profile := createProfileJson(phone, yob, region, sex, "")
    jsondata, _ := json.Marshal(profile)
    post_data := strings.NewReader(string(jsondata))

    // request
    url := "http://localhost:8000/v1/user/profile"
    req, _ := http.NewRequest("POST", url, post_data)
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("Authorization", "Bearer "+tokenString)

    // send
    resp, err := client.Do(req)
    assert.Nil(err)

    // get profile
    req, _ = http.NewRequest("GET", url, nil)
    req.Header.Set("Authorization", "Bearer "+tokenString)
    resp, err = client.Do(req)
    assert.Nil(err)
    assert.Equal(http.StatusOK, resp.StatusCode, "should response StatusOK")
    body, err := ioutil.ReadAll(resp.Body)
    defer resp.Body.Close()
    assert.Nil(err)

    responseData := new(cache.User)
    err = json.Unmarshal(body, responseData)
    assert.Nil(err)

    userid, _ := strconv.ParseInt(idString, 10, 64)
    assert.Equal(userid, responseData.Id, "should store correct userid in cache")
    assert.Equal(dummyUsername, responseData.Username, "should store correct username in cache")
    assert.Equal(region, responseData.Region, "should store correct region in cache")
    assert.Equal(sex, responseData.Sex, "should store correct sex in cache")
    assert.Equal(yob, responseData.Yob, "should store correct yob in cache")
}
