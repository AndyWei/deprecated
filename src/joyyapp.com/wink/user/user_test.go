package user

import (
    "encoding/json"
    . "github.com/smartystreets/goconvey/convey"
    "io/ioutil"
    "net/http"
    "strings"
    "testing"
)

func createCredentialJson(name, password string) *CredentialJson {
    return &CredentialJson{name, password}
}

type SignResponse struct {
    Id    int64  `json:"id"`
    Token string `json:"token"`
}

func TestSignup(t *testing.T) {
    Convey("Should be able to signup", t, func() {

        // request
        credential := createCredentialJson("lucky", "password")
        jsondata, _ := json.Marshal(credential)
        post_data := strings.NewReader(string(jsondata))
        req, _ := http.NewRequest("POST", "http://localhost:8000/v1/user/signup", post_data)
        req.Header.Set("Content-Type", "application/json")

        // send
        client := &http.Client{}
        res, _ := client.Do(req)
        So(res.StatusCode, ShouldEqual, 200)

        Convey("Should be able to parse body", func() {

            body, err := ioutil.ReadAll(res.Body)
            defer res.Body.Close()
            So(err, ShouldBeNil)

            Convey("Should be able to get json back", func() {

                responseData := new(SignResponse)
                err := json.Unmarshal(body, responseData)
                So(err, ShouldBeNil)

                // Convey("Should be able to be authorized", func() {
                //     token := responseData.Token
                //     req, _ := http.NewRequest("GET", "http://localhost:3000/api/auth/testAuth", nil)
                //     req.Header.Set("Authorization", "Bearer "+token)
                //     client = &http.Client{}
                //     res, _ := client.Do(req)
                //     So(res.StatusCode, ShouldEqual, 200)
                // })
            })
        })
    })

    // Convey("Should not be able to signup with false credentials", t, func() {
    //     user := createCredentialJson("jnwfkjnkfneknvjwenv", "wenknfkwnfknfknkfjnwkfenw")
    //     jsondata, _ := json.Marshal(user)
    //     post_data := strings.NewReader(string(jsondata))
    //     req, _ := http.NewRequest("POST", "http://localhost:3000/api/signup", post_data)
    //     req.Header.Set("Content-Type", "application/json")
    //     client := &http.Client{}
    //     res, _ := client.Do(req)
    //     So(res.StatusCode, ShouldEqual, 401)
    // })

    // Convey("Should not be able to authorize with false credentials", t, func() {
    //     token := ""
    //     req, _ := http.NewRequest("GET", "http://localhost:3000/api/auth/testAuth", nil)
    //     req.Header.Set("Authorization", "Bearer "+token)
    //     client := &http.Client{}
    //     res, _ := client.Do(req)
    //     So(res.StatusCode, ShouldEqual, 401)
    // })
}

func TestSignin(t *testing.T) {
    Convey("Should be able to signin", t, func() {

        // request
        credential := createCredentialJson("andy", "password")
        jsondata, _ := json.Marshal(credential)
        post_data := strings.NewReader(string(jsondata))
        req, _ := http.NewRequest("POST", "http://localhost:8000/v1/user/signin", post_data)
        req.Header.Set("Content-Type", "application/json")

        // send
        client := &http.Client{}
        res, _ := client.Do(req)
        So(res.StatusCode, ShouldEqual, 200)

        Convey("Should be able to parse body", func() {

            body, err := ioutil.ReadAll(res.Body)
            defer res.Body.Close()
            So(err, ShouldBeNil)

            Convey("Should be able to get json back", func() {

                responseData := new(SignResponse)
                err := json.Unmarshal(body, responseData)
                So(err, ShouldBeNil)

                // Convey("Should be able to be authorized", func() {
                //     token := responseData.Token
                //     req, _ := http.NewRequest("GET", "http://localhost:3000/api/auth/testAuth", nil)
                //     req.Header.Set("Authorization", "Bearer "+token)
                //     client = &http.Client{}
                //     res, _ := client.Do(req)
                //     So(res.StatusCode, ShouldEqual, 200)
                // })
            })
        })
    })
}
