package user

import (
    "encoding/json"
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
    {1234567890002, "user2", 14258009876, 3, 1, 1991, "bad girl in unknown region", http.StatusBadRequest},
    {1234567890003, "user3", 86136123412, 1, 0, 1992, "good man in china", http.StatusOK},
    {1234567890004, "user4", 86136123412, 1, 0, 1992, "", http.StatusOK},
}

func TestSetProfile(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, t := range UpdateProfileTests {

        body := fmt.Sprintf("phone=%v&region=%v&sex=%v&yob=%v", t.phone, t.region, t.sex, t.yob)
        if len(t.bio) > 0 {
            body += fmt.Sprintf("&bio=%v", url.QueryEscape(t.bio))
        }
        LogInfof("TestSetProfile body = %v", body)

        req, _ := http.NewRequest("POST", "/v1/user/profile", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.SetProfile(resp, req, t.userid, t.username)

        assert.Equal(t.code, resp.Code, "should response correct status code")
    }
}

var GetProfileTests = []struct {
    userid   int64
    username string
    phone    int64
    region   int
    sex      int
    yob      int
    bio      string
    code     int
}{
    {1234567891111, "get_profile_user1", 16509001234, 0, 0, 1990, "good man in us", http.StatusOK},
    {1234567892222, "get_profile_user2", 86136123412, 1, 0, 1992, "ddd", http.StatusOK},
}

type GetProfileReply struct {
    Username string `json:"username"`
    Phone    int64  `json:"phone"`
    Region   int    `json:"region"`
    Sex      int    `json:"sex"`
    Yob      int    `json:"yob"`
    Bio      string `json:"bio"`
}

func TestGetProfile(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, t := range GetProfileTests {

        body := fmt.Sprintf("phone=%v&region=%v&sex=%v&yob=%v", t.phone, t.region, t.sex, t.yob)
        if len(t.bio) > 0 {
            body += fmt.Sprintf("&bio=%v", url.QueryEscape(t.bio))
        }

        req, _ := http.NewRequest("POST", "/v1/user/profile", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.SetProfile(resp, req, t.userid, t.username)
        assert.Equal(t.code, resp.Code, "should response correct status code")

        req2, _ := http.NewRequest("GET", "/v1/user/profile", nil)
        resp2 := httptest.NewRecorder()
        h.GetProfile(resp2, req2, t.userid, t.username)

        bytes := resp2.Body.Bytes()
        jsonstr := string(bytes)
        LogInfof("jsonstr = %v", jsonstr)

        var r GetProfileReply
        err := json.Unmarshal(bytes, &r)
        LogError(err)

        assert.Nil(err)
        assert.Equal(t.phone, r.Phone, "should store correct region in DB")
        assert.Equal(t.sex, r.Sex, "should store correct sex in DB")
        assert.Equal(t.yob, r.Yob, "should store correct yob in DB")
        assert.Equal(t.bio, r.Bio, "should store correct bio in DB")
    }
}
