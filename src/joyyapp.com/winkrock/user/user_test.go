package user

import (
    "encoding/json"
    "fmt"
    "github.com/stretchr/testify/assert"
    "joyyapp.com/winkrock/cassandra"
    . "joyyapp.com/winkrock/util"
    "net/http"
    "net/http/httptest"
    "net/url"
    "strings"
    "testing"
)

/*
 * Create Profile Test
 */
var CreateProfileTests = []struct {
    userid   int64
    username string
    phone    int64
    yrs      int
    bio      string
    code     int
}{
    {1234567890001, "user1", 16509001234, 2, "good man in us", http.StatusOK},
    {1234567890002, "user2", 14258009876, 0, "bad girl in unknown region", http.StatusBadRequest},
    {1234567890003, "user3", 86136123412, 2, "good man in china", http.StatusOK},
    {1234567890004, "user4", 86136123412, 2, "", http.StatusOK},
}

func TestCreateProfile(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, t := range CreateProfileTests {

        body := fmt.Sprintf("phone=%v&yrs=%v", t.phone, t.yrs)
        if len(t.bio) > 0 {
            body += fmt.Sprintf("&bio=%v", url.QueryEscape(t.bio))
        }

        req, _ := http.NewRequest("POST", "/v1/user/profile", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.CreateProfile(resp, req, t.userid, t.username)

        assert.Equal(t.code, resp.Code, "should response correct status code")
    }
}

/*
 * Read Profile Test
 */
var ReadProfileTests = []struct {
    userid   int64
    username string
    phone    int64
    yrs      int
    bio      string
    code     int
}{
    {1234567891111, "get_profile_user1", 16509001234, 1990001002, "good man in us", http.StatusOK},
    {1234567892222, "get_profile_user2", 86136123412, 1992001002, "ddd", http.StatusOK},
}

type ReadProfileReply struct {
    Username string `json:"username"`
    Phone    int64  `json:"phone"`
    YRS      int    `json:"yrs"`
    Bio      string `json:"bio"`
}

func TestReadProfile(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, t := range ReadProfileTests {

        body := fmt.Sprintf("phone=%v&yrs=%v", t.phone, t.yrs)
        if len(t.bio) > 0 {
            body += fmt.Sprintf("&bio=%v", url.QueryEscape(t.bio))
        }

        req, _ := http.NewRequest("POST", "/v1/user/profile", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.CreateProfile(resp, req, t.userid, t.username)
        assert.Equal(t.code, resp.Code, "should response correct status code")

        req2, _ := http.NewRequest("GET", "/v1/user/profile", nil)
        resp2 := httptest.NewRecorder()
        h.ReadProfile(resp2, req2, t.userid, t.username)

        bytes := resp2.Body.Bytes()

        var r ReadProfileReply
        err := json.Unmarshal(bytes, &r)
        LogError(err)

        assert.Nil(err)
        assert.Equal(t.phone, r.Phone, "should store correct region in DB")
        assert.Equal(t.yrs, r.YRS, "should store correct yrs in DB")
        assert.Equal(t.bio, r.Bio, "should store correct bio in DB")
    }
}

/*
 * Appear Test
 */
var AppearTests = []struct {
    userid   int64
    username string
    country  string
    zip      string
    yrs      int
    code     int
}{
    {1234567890001, "user1", "US", "94536", 19900101, http.StatusOK},
    {1234567890002, "user2", "US", "94538", 0, http.StatusBadRequest},
    {1234567890003, "user3", "US", "*9455", 19900101, http.StatusBadRequest},
    {1234567890004, "user4", "USA", "94555", 19900101, http.StatusBadRequest},
    {1234567890005, "user5", "US", "94536", 1992, http.StatusOK},
}

func TestAppear(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, t := range AppearTests {

        body := fmt.Sprintf("country=%v&zip=%v&yrs=%v", url.QueryEscape(t.country), url.QueryEscape(t.zip), t.yrs)

        req, _ := http.NewRequest("POST", "/v1/user/appear", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.Appear(resp, req, t.userid, t.username)

        assert.Equal(t.code, resp.Code, "should response correct status code")
    }
}

/*
 * User Test
 */
var Users = []struct {
    userid   int64
    username string
    country  string
    zip      string
    yrs      int
}{
    {1234567890000, "user0", "US", "94530", 000001},
    {1234567890001, "user1", "US", "94531", 000001},
    {1234567890002, "user2", "US", "94532", 000001},
    {1234567890003, "user3", "US", "94533", 000001},
    {1234567890004, "user4", "US", "94534", 000001},
    {1234567890005, "user5", "US", "94535", 000001},
    {1234567890006, "user6", "US", "94536", 000001},
    {1234567890007, "user7", "US", "94537", 000001},
    {1234567890008, "user8", "US", "94538", 000001},
    {1234567890009, "user9", "US", "94539", 000001},
    {1234567890010, "userA", "US", "94530", 000001},
    {1234567890011, "userB", "US", "94531", 000001},
    {1234567890012, "userC", "US", "94532", 000001},
    {1234567890013, "userD", "US", "94533", 000001},
    {1234567890014, "userE", "US", "94534", 000001},
    {1234567890015, "userF", "US", "94535", 000001},
    {1234567890016, "userG", "US", "94536", 000001},
    {1234567890017, "userH", "US", "94537", 000001},
    {1234567890018, "userI", "US", "94538", 000001},
    {1234567890019, "userJ", "US", "94539", 000001},
}

func (h *Handler) prepareUsers() {

    for _, t := range Users {

        body := fmt.Sprintf("country=%v&zip=%v&yrs=%v", url.QueryEscape(t.country), url.QueryEscape(t.zip), t.yrs)

        req, _ := http.NewRequest("POST", "/v1/user/appear", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        resp := httptest.NewRecorder()

        h.Appear(resp, req, t.userid, t.username)
    }
}

type User struct {
    Userid   int64  `json:"userid"`
    Username string `json:"username"`
    YRS      int    `json:"yrs"`
}

var ReadUsersTests = []struct {
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

func TestReadUsers(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}
    h.prepareUsers()

    sex := 1 // the same as the users in Users, whose sex are all 1
    for _, t := range ReadUsersTests {
        query := fmt.Sprintf("/v1/users?country=%v&sex=%v&zip=%v", url.QueryEscape("US"), sex, url.QueryEscape(t.zip))
        req, _ := http.NewRequest("GET", query, nil)
        resp := httptest.NewRecorder()
        h.ReadUsers(resp, req, int64(1), "username")

        bytes := resp.Body.Bytes()

        var r []User
        err := json.Unmarshal(bytes, &r)

        assert.Nil(err)
        assert.Equal(t.count, len(r), "should store user profiles on each level of user_csz")
    }
}
