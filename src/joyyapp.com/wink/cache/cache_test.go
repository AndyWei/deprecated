package cache

import (
    "github.com/stretchr/testify/assert"
    "testing"
)

func TestSetAndGetUserStruct(t *testing.T) {

    assert := assert.New(t)

    userid := int64(1234567890)
    username := "kkmm12345"
    region := 1
    sex := 1
    yob := 1990
    u := &User{userid, username, region, sex, yob}
    err := SetUserStruct(u)
    assert.Nil(err)

    value, err := GetUserStruct(userid)
    assert.Nil(err)
    assert.Equal(userid, value.Id, "should store correct userid in cache")
    assert.Equal(username, value.Username, "should store correct username in cache")
    assert.Equal(region, value.Region, "should store correct region in cache")
    assert.Equal(sex, value.Sex, "should store correct sex in cache")
    assert.Equal(yob, value.Yob, "should store correct yob in cache")
}

func TestGetNonExistUserStruct(t *testing.T) {

    assert := assert.New(t)
    userid := int64(34559078)

    value, err := GetUserStruct(userid)
    assert.Nil(err)
    assert.Equal(int64(0), value.Id, "should store correct userid in cache")
    assert.Equal("", value.Username, "should store correct username in cache")
    assert.Equal(0, value.Region, "should store correct region in cache")
    assert.Equal(0, value.Sex, "should store correct sex in cache")
    assert.Equal(0, value.Yob, "should store correct yob in cache")
}
