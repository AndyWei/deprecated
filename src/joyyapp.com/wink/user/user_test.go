package user

import (
    "fmt"
    "github.com/stretchr/testify/assert"
    "joyyapp.com/wink/cassandra"
    . "joyyapp.com/wink/util"
    "net/http"
    "net/http/httptest"
    "net/url"
    "strings"
    "testing"
)

var UpdateProfileTests = []struct {
    userid   int64
    username string
    phone    int64
    region   int
    sex      int
    yob      int
    bio      string
    code     int
}{
    {1234567890001, "user1", 16509001234, 0, 0, 1990, "good man in us", http.StatusOK},
    // {1234567890002, "user2", 14258009876, 3, 1, 1991, "bad girl in unknown region", http.StatusBadRequest},
    // {1234567890003, "user3", 86136123412, 1, 0, 1992, "good man in china", http.StatusOK},
    // {1234567890004, "user4", 86136123412, 1, 0, 1992, "", http.StatusOK},
}

func TestSetProfile(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, t := range UpdateProfileTests {

        body := fmt.Sprintf("phone=%v&region=%v&sex=%v&yob=%v&bio=%v", t.phone, t.region, t.sex, t.yob, url.QueryEscape(t.bio))
        LogInfof("TestSetProfile body = %v", body)
        req, _ := http.NewRequest("POST", "/v1/user/profile", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.SetProfile(resp, req, t.userid, t.username)

        assert.Equal(t.code, resp.Code, "should response correct status code")
    }
}

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
