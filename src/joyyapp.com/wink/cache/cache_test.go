package cache

import (
    "github.com/stretchr/testify/assert"
    "testing"
)

func TestSetAndGetUserStruct(t *testing.T) {

    assert := assert.New(t)

    userid := int64(1234567890)
    username := "kkmm12345"
    avatar := "kkm_9527.jpg"
    sex := "f"
    yob := 1990
    u := &User{userid, username, avatar, sex, yob}
    err := SetUserStruct(u)
    assert.Nil(err)

    value, err := GetUserStruct(userid)
    assert.Nil(err)
    assert.Equal(userid, value.Id, "should store correct userid in cache")
    assert.Equal(username, value.Username, "should store correct username in cache")
    assert.Equal(avatar, value.Avatar, "should store correct avatar in cache")
    assert.Equal(sex, value.Sex, "should store correct sex in cache")
    assert.Equal(yob, value.Yob, "should store correct yob in cache")
}
