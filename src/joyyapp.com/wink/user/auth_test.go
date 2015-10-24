package user

import (
    "encoding/json"
    "errors"
    "github.com/stretchr/testify/assert"
    "joyyapp.com/wink/cassandra"
    . "joyyapp.com/wink/util"
    "net/http"
    "net/http/httptest"
    "net/url"
    "strconv"
    "testing"
)

var signupTests = []struct {
    username string
    password string
    code     int
}{
    {"dummy_user", "dummy_user", http.StatusOK},
    {"dummy_user", "dummy_user", http.StatusBadRequest},
    {"", "", http.StatusBadRequest},
    {"", "dummy_user_2", http.StatusBadRequest},
    {"dummy_user_2", "", http.StatusBadRequest},
}

func TestSignUp(t *testing.T) {

    assert := assert.New(t)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, test := range signupTests {
        v := url.Values{}
        v.Set("username", test.username)
        v.Set("password", test.password)
        r, _ := http.NewRequest("POST", "/user/signup", nil)
        r.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        r.PostForm = v
        resp := httptest.NewRecorder()
        h.SignUp(resp, r, nil)

        assert.Equal(test.code, resp.Code, "should response correct status code")

        if test.code == http.StatusOK {
            bytes := resp.Body.Bytes()
            reply := &AuthReply{}
            err := json.Unmarshal(bytes, reply)

            assert.Nil(err)
            assert.NotNil(reply.Id)
            assert.NotNil(reply.Token)
        }
    }
}

var signinTests = []struct {
    username string
    password string
    code     int
}{
    {"dummy_user", "dummy_user", http.StatusOK},
    {"dummy_user", "dummy_user", http.StatusOK},
    {"dummy_user", "bad_password", http.StatusUnauthorized},
    {"", "", http.StatusBadRequest},
    {"", "dummy_user_2", http.StatusBadRequest},
    {"dummy_user_2", "", http.StatusBadRequest},
}

func TestSignIn(t *testing.T) {

    assert := assert.New(t)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, test := range signinTests {
        v := url.Values{}
        v.Set("username", test.username)
        v.Set("password", test.password)
        r, _ := http.NewRequest("POST", "/user/signin", nil)
        r.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        r.PostForm = v
        resp := httptest.NewRecorder()
        h.SignIn(resp, r, nil)

        assert.Equal(test.code, resp.Code, "should response correct status code")

        if test.code == http.StatusOK {
            bytes := resp.Body.Bytes()
            reply := &AuthReply{}
            err := json.Unmarshal(bytes, reply)

            assert.Nil(err)
            assert.NotNil(reply.Id)
            assert.NotNil(reply.Token)
        }
    }
}

var checkExistenceTests = []struct {
    username string
    password string
    userid   int64
    server   string
    code     int
}{
    {"dummy_user", "dummy_user", 0, "joyy.im", http.StatusOK},
    {"dummy_user", "dummy_user", 1, "jjjj.im", http.StatusBadRequest},
    {"dummy_user", "dummy_user", 1, "joyy.im", http.StatusNotFound},
}

func TestCheckExistence(t *testing.T) {

    assert := assert.New(t)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, test := range checkExistenceTests {
        id, _, _ := h.signin(test.username, test.password)

        v := url.Values{}
        userid := test.userid
        if userid == 0 {
            userid = id
        }
        v.Set("user", strconv.FormatInt(userid, 10))
        v.Set("server", test.server)
        r, _ := http.NewRequest("GET", "/xmpp/user_exists", nil)
        r.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        r.PostForm = v
        resp := httptest.NewRecorder()
        h.CheckExistence(resp, r, nil)

        assert.Equal(test.code, resp.Code, "should response correct status code")
    }
}

var checkPasswordTests = []struct {
    username string
    password string
    pass     string
    server   string
    code     int
}{
    {"dummy_user", "dummy_user", "good_token", "joyy.im", http.StatusOK},
    {"dummy_user", "dummy_user", "good_token", "jjjj.im", http.StatusBadRequest},
    {"dummy_user", "dummy_user", "bad_token", "joyy.im", http.StatusUnauthorized},
}

func TestCheckPassword(t *testing.T) {

    assert := assert.New(t)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, test := range checkPasswordTests {
        userid, token, _ := h.signin(test.username, test.password)

        v := url.Values{}
        pass := test.pass
        if pass != "bad_token" {
            pass = token
        }
        v.Set("user", strconv.FormatInt(userid, 10))
        v.Set("server", test.server)
        v.Set("pass", pass)
        r, _ := http.NewRequest("GET", "/xmpp/check_password", nil)
        r.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
        r.PostForm = v
        resp := httptest.NewRecorder()
        h.CheckPassword(resp, r, nil)

        assert.Equal(test.code, resp.Code, "should response correct status code")
    }
}

func (h *Handler) signin(username, password string) (id int64, token string, err error) {

    v := url.Values{}
    v.Set("username", username)
    v.Set("password", password)
    r, _ := http.NewRequest("POST", "/user/signin", nil)
    r.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")
    r.PostForm = v
    resp := httptest.NewRecorder()
    h.SignIn(resp, r, nil)

    if resp.Code != http.StatusOK {
        return 0, "", errors.New(ErrPasswordInvalid)
    }

    bytes := resp.Body.Bytes()
    reply := &AuthReply{}
    if err := json.Unmarshal(bytes, reply); err != nil {
        return 0, "", errors.New(ErrPasswordInvalid)
    }

    return reply.Id, reply.Token, nil
}
