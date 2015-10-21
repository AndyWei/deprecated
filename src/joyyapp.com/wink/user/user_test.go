package user

import (
    "encoding/json"
    "github.com/stretchr/testify/assert"
    "io/ioutil"
    "joyyapp.com/wink/cache"
    . "joyyapp.com/wink/util"
    "net/http"
    "strconv"
    "strings"
    "testing"
)

func createProfileParams(phone int64, yob, region, sex int, bio string) *ProfileParams {
    return &ProfileParams{Phone: phone, Region: region, Sex: sex, Yob: yob, Bio: bio}
}

func createFriendshipParams(fid int64, fname string, fregion, region int) *FriendshipParams {
    return &FriendshipParams{Fid: fid, Fname: fname, Fregion: fregion, Region: region}
}

func TestSetProfile(t *testing.T) {

    assert := assert.New(t)
    dummyUsername := "dummy_for_set"

    idString, tokenString := signup(dummyUsername, "profile")

    // payload
    payload := createProfileParams(int64(14257850318), 1995, 0, 1, "let's make a miracle")
    jsondata, _ := json.Marshal(payload)
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

    responseData := new(DefaultPostResponse)
    err = json.Unmarshal(body, responseData)
    assert.Nil(err)
    assert.Equal(0, responseData.Error, "should contain error code in response")

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

    payload := createProfileParams(phone, yob, region, sex, "")
    jsondata, _ := json.Marshal(payload)
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

func TestCreateFriendship(t *testing.T) {

    assert := assert.New(t)

    dummyUsername := "dummy_for_friendship"
    _, tokenString := signup(dummyUsername, "profile")

    // set profile first
    fid := int64(14008009000)
    fname := "bff"
    fregion := 0
    region := 1

    payload := createFriendshipParams(fid, fname, fregion, region)
    jsondata, _ := json.Marshal(payload)
    post_data := strings.NewReader(string(jsondata))

    // request
    url := "http://localhost:8000/v1/user/friendship/create"
    req, _ := http.NewRequest("POST", url, post_data)
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("Authorization", "Bearer "+tokenString)

    // send
    resp, err := client.Do(req)
    assert.Nil(err)

    // get friends
    url = "http://localhost:8000/v1/user/friends"
    req, _ = http.NewRequest("GET", url, nil)
    req.Header.Set("Authorization", "Bearer "+tokenString)
    resp, err = client.Do(req)
    assert.Nil(err)
    assert.Equal(http.StatusOK, resp.StatusCode, "should response StatusOK")
    body, err := ioutil.ReadAll(resp.Body)
    defer resp.Body.Close()
    assert.Nil(err)

    var friends []Friend
    err = json.Unmarshal(body, &friends)
    assert.Nil(err)

    var friend Friend = friends[0]
    assert.Equal(fid, friend.Id, "should store correct userid in DB")
    assert.Equal(fname, friend.Username, "should store correct username in DB")
    assert.Equal(fregion, friend.Region, "should store correct region in DB")
}
