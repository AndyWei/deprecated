package idgen

import (
    convey "github.com/smartystreets/goconvey/convey"
    "testing"
    "time"
)

func Now() string {
    return time.Now().Format("2015-07-25 23:02:00")
}

func TestNotErr(t *testing.T) {
    convey.Convey("should not err", t, func() {

        err, generator := SharedIdGenerator(1)
        if err != nil {
            t.Fatal("can not initialize")
        }

        for i := 0; i < 10; i++ {
            err, _ := generator.NextId()
            convey.So(err, convey.ShouldBeNil)
        }
    })

}

func TestContainsMachineId(t *testing.T) {
    convey.Convey("generated id should contains the `workerId`", t, func() {

        var workerId int64
        for workerId = 0; workerId < 1024; workerId++ {
            err, generator := SharedIdGenerator(workerId)

            if err != nil {
                t.Fatal("can not initialize")
            }

            for i := 0; i < 1; i++ {
                _, newId := generator.NextId()
                newId2 := uint(newId << 42)
                newId3 := uint(newId2 >> 54)

                convey.So(newId3, convey.ShouldEqual, workerId)
            }
        }
    })
}

func TestMachineId(t *testing.T) {
    convey.Convey("method 'MachineId' should return the right workerId", t, func() {

        var workerId int64
        for workerId = 0; workerId < 1024; workerId++ {

            err, generator := SharedIdGenerator(workerId)

            if err != nil {
                t.Fatal("can not initialize")
            }

            for i := 0; i < 1; i++ {
                _, newId := generator.NextId()

                wId := generator.MachineId(newId)
                convey.So(wId, convey.ShouldEqual, workerId)
            }
        }
    })
}
