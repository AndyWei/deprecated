package user

import (
// "encoding/json"
// "github.com/stretchr/testify/assert"
// "io/ioutil"
// "joyyapp.com/wink/cassandra"
// . "joyyapp.com/wink/util"
// "net/http"
// "strconv"
// "strings"
// "testing"
)

// var ProfileTests = []struct {
//     phone  int64
//     region int
//     sex    int
//     yob    int
//     bio    string
// }{
//     {int64(16509001234), 0, 0, 1990, "good man in us"},
//     {int64(14258009876), 3, 1, 1991, "good girl in eu"},
//     {int64(8613612341234), 1, 0, 1992, "good man in china"},
// }

// func createProfileParams(phone int64, yob, region, sex int, bio string) *ProfileParams {
//     return &ProfileParams{Phone: phone, Region: region, Sex: sex, Yob: yob, Bio: bio}
// }

// func TestSetProfile(t *testing.T) {

//     assert := assert.New(t)

//     db := cassandra.DB()
//     u := &user.Handler{db}

//     for i, test := range ProfileTests {

//         c * gin.Context =
//             u.SetProfile(c)
//         if useProxy(test.host+":80") != test.match {
//             t.Errorf("useProxy(%v) = %v, want %v", test.host, !test.match, test.match)
//         }
//     }
//     dummyUsername := "dummy_for_set"

//     idString, tokenString := signup(dummyUsername, "profile")

//     // payload
//     payload := createProfileParams(int64(14257850318), 1995, 0, 1, "let's make a miracle")
//     bytes, _ := json.Marshal(payload)
//     body := strings.NewReader(string(bytes))

//     // request
//     url := "http://localhost:8000/v1/user/profile"
//     req, _ := http.NewRequest("POST", url, body)
//     req.Header.Set("Content-Type", "application/json")
//     req.Header.Set("Authorization", "Bearer "+tokenString)

//     // send
//     resp, err := client.Do(req)
//     assert.Nil(err)

//     // check response
//     assert.Equal(http.StatusOK, resp.StatusCode, "should response StatusOK")
//     body, err := ioutil.ReadAll(resp.Body)
//     defer resp.Body.Close()
//     assert.Nil(err)

//     responseData := new(DefaultPostResponse)
//     err = json.Unmarshal(body, responseData)
//     assert.Nil(err)
//     assert.Equal(0, responseData.Error, "should contain error code in response")

//     // check cache
//     u, err := cache.GetUserStruct(idString)
//     assert.Nil(err)
//     assert.Equal(dummyUsername, u.Username, "should store correct username in cache")
//     id, _ := strconv.ParseInt(idString, 10, 64)
//     assert.Equal(id, u.Id, "should store correct userid in cache")
// }

// func TestGetProfile(t *testing.T) {

//     assert := assert.New(t)

//     dummyUsername := "dummy_for_get"
//     idString, tokenString := signup(dummyUsername, "profile")

//     // set profile first
//     phone := int64(14008009000)
//     region := 1
//     sex := 2
//     yob := 1990

//     payload := createProfileParams(phone, yob, region, sex, "")
//     bytes, _ := json.Marshal(payload)
//     body := strings.NewReader(string(bytes))

//     // request
//     url := "http://localhost:8000/v1/user/profile"
//     req, _ := http.NewRequest("POST", url, body)
//     req.Header.Set("Content-Type", "application/json")
//     req.Header.Set("Authorization", "Bearer "+tokenString)

//     // send
//     resp, err := client.Do(req)
//     assert.Nil(err)

//     // get profile
//     req, _ = http.NewRequest("GET", url, nil)
//     req.Header.Set("Authorization", "Bearer "+tokenString)
//     resp, err = client.Do(req)
//     assert.Nil(err)
//     assert.Equal(http.StatusOK, resp.StatusCode, "should response StatusOK")
//     body, err := ioutil.ReadAll(resp.Body)
//     defer resp.Body.Close()
//     assert.Nil(err)

//     u := new(cache.User)
//     err = json.Unmarshal(body, u)
//     assert.Nil(err)

//     userid, _ := strconv.ParseInt(idString, 10, 64)
//     assert.Equal(userid, u.Id, "should store correct userid in cache")
//     assert.Equal(dummyUsername, u.Username, "should store correct username in cache")
//     assert.Equal(region, u.Region, "should store correct region in cache")
//     assert.Equal(sex, u.Sex, "should store correct sex in cache")
//     assert.Equal(yob, u.Yob, "should store correct yob in cache")
// }
