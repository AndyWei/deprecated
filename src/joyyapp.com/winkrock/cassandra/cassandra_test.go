/*
 * cassandra_test.go
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package cassandra

import (
    "github.com/stretchr/testify/assert"
    "testing"
)

func TestDB(t *testing.T) {
    assert := assert.New(t)
    db := DB()
    assert.NotNil(db, "shared DB instance should not be nil")
}
