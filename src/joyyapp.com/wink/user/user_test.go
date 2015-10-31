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

/*
 * Update Profile Test
 */
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

        req, _ := http.NewRequest("POST", "/v1/user/profile", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.SetProfile(resp, req, t.userid, t.username)

        assert.Equal(t.code, resp.Code, "should response correct status code")
    }
}

/*
 * Get Profile Test
 */
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
        h.Profile(resp2, req2, t.userid, t.username)

        bytes := resp2.Body.Bytes()

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

/*
 * Occur Test
 */
var OccurTests = []struct {
    userid   int64
    username string
    country  string
    sex      string
    zip      string
    region   int
    yob      int
    code     int
}{
    {1234567890001, "user1", "US", "M", "94536", 0, 1990, http.StatusOK},
    {1234567890002, "user2", "US", "2", "94538", 1, 1991, http.StatusBadRequest},
    {1234567890003, "user3", "US", "F", "*9455", 2, 1992, http.StatusBadRequest},
    {1234567890004, "user4", "USA", "F", "94555", 2, 1992, http.StatusBadRequest},
    {1234567890005, "user5", "US", "X", "94536", 2, 1992, http.StatusOK},
}

func TestOccur(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, t := range OccurTests {

        body := fmt.Sprintf("country=%v&sex=%v&zip=%v&region=%v&yob=%v", url.QueryEscape(t.country), url.QueryEscape(t.sex), url.QueryEscape(t.zip), t.region, t.yob)

        req, _ := http.NewRequest("POST", "/v1/user/occur", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.Occur(resp, req, t.userid, t.username)

        assert.Equal(t.code, resp.Code, "should response correct status code")
    }
}

/*
 * Nearby Test
 */
var Users = []struct {
    userid   int64
    username string
    country  string
    sex      string
    zip      string
    region   int
    yob      int
}{
    {1234567890000, "user0", "US", "F", "94530", 1, 1990},
    {1234567890001, "user1", "US", "F", "94531", 0, 1990},
    {1234567890002, "user2", "US", "F", "94532", 1, 1990},
    {1234567890003, "user3", "US", "F", "94533", 2, 1990},
    {1234567890004, "user4", "US", "F", "94534", 2, 1990},
    {1234567890005, "user5", "US", "F", "94535", 0, 1990},
    {1234567890006, "user6", "US", "F", "94536", 1, 1990},
    {1234567890007, "user7", "US", "F", "94537", 2, 1990},
    {1234567890008, "user8", "US", "F", "94538", 2, 1990},
    {1234567890009, "user9", "US", "F", "94539", 0, 1990},
    {1234567890010, "userA", "US", "F", "94530", 1, 1990},
    {1234567890011, "userB", "US", "F", "94531", 2, 1990},
    {1234567890012, "userC", "US", "F", "94532", 2, 1990},
    {1234567890013, "userD", "US", "F", "94533", 2, 1990},
    {1234567890014, "userE", "US", "F", "94534", 2, 1990},
    {1234567890015, "userF", "US", "F", "94535", 0, 1990},
    {1234567890016, "userG", "US", "F", "94536", 1, 1990},
    {1234567890017, "userH", "US", "F", "94537", 2, 1990},
    {1234567890018, "userI", "US", "F", "94538", 2, 1990},
    {1234567890019, "userJ", "US", "F", "94539", 0, 1990},
}

func (h *Handler) prepareUsers() {

    for _, t := range Users {

        body := fmt.Sprintf("country=%v&sex=%v&zip=%v&region=%v&yob=%v", url.QueryEscape(t.country), url.QueryEscape(t.sex), url.QueryEscape(t.zip), t.region, t.yob)

        req, _ := http.NewRequest("POST", "/v1/user/occur", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.Occur(resp, req, t.userid, t.username)
    }
}

type AreaUser struct {
    Userid   int64  `json:"userid"`
    Username string `json:"username"`
    Region   int    `json:"region"`
    Yob      int    `json:"yob"`
}

var NearbyTests = []struct {
    zip   string
    count int
}{
    {"94530", 2},
    {"94531", 2},
    {"94532", 2},
    {"94533", 2},
    {"94534", 2},
    {"94535", 2},
    {"94536", 2},
    {"94537", 2},
    {"94538", 2},
    {"94539", 2},
    {"9453", 20},
    {"945", 20},
    {"94", 20},
    {"9", 20},
}

func TestNearby(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}
    h.prepareUsers()

    for _, t := range NearbyTests {
        query := fmt.Sprintf("/v1/user/nearby?country=%v&sex=%v&zip=%v", url.QueryEscape("US"), url.QueryEscape("F"), url.QueryEscape(t.zip))
        req, _ := http.NewRequest("GET", query, nil)
        resp := httptest.NewRecorder()
        h.Nearby(resp, req, int64(1), "username")

        bytes := resp.Body.Bytes()

        var r []AreaUser
        err := json.Unmarshal(bytes, &r)

        assert.Nil(err)
        assert.Equal(t.count, len(r), "should store user profiles on each level of user_csz")
    }
}
