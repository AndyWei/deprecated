package auth

import (
    "github.com/stretchr/testify/assert"
    "testing"
)

var JwtTests = []struct {
    userid   int64
    username string
}{
    {100110011001, "user_shgfjief_1"},
    {100110011002, "user_shgsdqid_2"},
    {100110011003, "user_klinmert_3"},
    {100110011004, "user_facebook_4"},
}

func TestJWT(test *testing.T) {
    assert := assert.New(test)

    for _, t := range JwtTests {

        token, err := NewToken(t.userid, t.username)
        assert.Nil(err)
        assert.NotEmpty(token)

        userid, username, err := ExtractToken(token)
        assert.Nil(err)
        assert.Equal(t.userid, userid, "should get correct userid")
        assert.Equal(t.username, username, "should get correct username")
    }
}
