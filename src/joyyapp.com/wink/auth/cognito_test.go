/*
 * cognito_test.go
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package auth

import (
    "github.com/stretchr/testify/assert"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestCognito(test *testing.T) {
    assert := assert.New(test)

    h := &Handler{}

    userid := int64(12345)
    username := "username"

    req, _ := http.NewRequest("GET", "/v1/auth/cognito", nil)
    resp := httptest.NewRecorder()
    h.Cognito(resp, req, userid, username)

    assert.Equal(http.StatusOK, resp.Code, "should response correct status code")
}
