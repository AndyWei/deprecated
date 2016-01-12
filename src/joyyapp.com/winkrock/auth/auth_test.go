package auth

import (
    "encoding/json"
    "errors"
    "fmt"
    "github.com/stretchr/testify/assert"
    "joyyapp.com/winkrock/cassandra"
    . "joyyapp.com/winkrock/util"
    "net/http"
    "net/http/httptest"
    "strings"
    "testing"
)

var signupTests = []struct {
    username string
    password string
    code     int
}{
    {"dummy_user", "dummy_password", http.StatusOK},
    {"dummy_user", "dummy_password", http.StatusBadRequest},
    {"", "", http.StatusBadRequest},
    {"", "dummy_password", http.StatusBadRequest},
    {"dummy_user", "", http.StatusBadRequest},
}

func TestSignUp(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, t := range signupTests {

        body := fmt.Sprintf("username=%v&password=%v", t.username, t.password)
        req, _ := http.NewRequest("POST", "/v1/auth/signup", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")

        resp := httptest.NewRecorder()
        h.SignUp(resp, req)

        assert.Equal(t.code, resp.Code, "should response correct status code")

        if t.code == http.StatusOK {
            bytes := resp.Body.Bytes()
            var r AuthResponse
            err := json.Unmarshal(bytes, &r)

            assert.Nil(err)
            assert.NotNil(r.Id)
            assert.NotNil(r.Token)
        }
    }
}

var signinTests = []struct {
    username string
    password string
    code     int
}{
    {"dummy_user", "dummy_password", http.StatusOK},
    {"dummy_user", "dummy_password", http.StatusOK},
    {"dummy_user", "bad_password", http.StatusUnauthorized},
    {"", "", http.StatusBadRequest},
    {"", "dummy_password", http.StatusBadRequest},
    {"dummy_user", "", http.StatusBadRequest},
}

func TestSignIn(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, t := range signinTests {
        body := fmt.Sprintf("username=%v&password=%v", t.username, t.password)
        req, _ := http.NewRequest("POST", "/v1/auth/signin", strings.NewReader(body))
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")

        resp := httptest.NewRecorder()
        h.SignIn(resp, req)

        assert.Equal(t.code, resp.Code, "should response correct status code")

        if t.code == http.StatusOK {
            bytes := resp.Body.Bytes()
            var r AuthResponse
            err := json.Unmarshal(bytes, &r)

            assert.Nil(err)
            assert.NotNil(r.Id)
            assert.NotNil(r.Token)
        }
    }
}

var checkExistenceTests = []struct {
    username string
    password string
    server   string
    code     int
}{
    {"check_existence_user1", "dummy_password", "winkrock.com", http.StatusOK},
    {"check_existence_user2", "dummy_password", "jjjj.im", http.StatusBadRequest},
}

func TestCheckExistence(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, t := range checkExistenceTests {
        userid, token, err := h.signUp(t.username, t.password)
        LogError(err)
        assert.Nil(err)
        assert.NotZero(userid)
        assert.NotEmpty(token)

        url := fmt.Sprintf("/v1/xmpp/user_exists?user=%v&server=%v", userid, t.server)
        req, _ := http.NewRequest("GET", url, nil)

        resp := httptest.NewRecorder()
        h.CheckExistence(resp, req)

        assert.Equal(t.code, resp.Code, "should response correct status code")
    }
}

var checkPasswordTests = []struct {
    username string
    password string
    pass     string
    server   string
    code     int
}{
    {"check_password_user1", "dummy_password", "good_token", "winkrock.com", http.StatusOK},
    {"check_password_user2", "dummy_password", "good_token", "jjjj.im", http.StatusBadRequest},
    {"check_password_user3", "dummy_password", "bad_token", "winkrock.com", http.StatusUnauthorized},
}

func TestCheckPassword(test *testing.T) {
    assert := assert.New(test)
    db := cassandra.DB()
    h := Handler{DB: db}

    for _, t := range checkPasswordTests {
        userid, token, _ := h.signUp(t.username, t.password)

        pass := t.pass
        if pass != "bad_token" {
            pass = token
        }

        url := fmt.Sprintf("/v1/xmpp/check_password?user=%v&server=%v&pass=%v", userid, t.server, pass)
        req, _ := http.NewRequest("GET", url, nil)

        resp := httptest.NewRecorder()
        h.CheckPassword(resp, req)

        assert.Equal(t.code, resp.Code, "should response correct status code")
    }
}

func (h *Handler) signUp(username, password string) (id int64, token string, err error) {
    body := fmt.Sprintf("username=%v&password=%v", username, password)
    req, _ := http.NewRequest("POST", "/v1/auth/signup", strings.NewReader(body))
    req.Header.Set("Content-Type", "application/x-www-form-urlencoded; param=value")

    resp := httptest.NewRecorder()
    h.SignUp(resp, req)

    bytes := resp.Body.Bytes()
    if resp.Code != http.StatusOK {
        return 0, "", errors.New(string(bytes))
    }

    var reply AuthResponse
    json.Unmarshal(bytes, &reply)

    return reply.Id, reply.Token, nil
}
