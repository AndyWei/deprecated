package main

import (
    "github.com/smartystreets/goconvey/convey"
    "testing"
)

func TestNotErr(t *testing.T) {
    convey.Convey("should not err", t, func() {

        convey.So(nil, convey.ShouldBeNil)
    })
}
