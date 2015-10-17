package idgen

import (
    . "github.com/smartystreets/goconvey/convey"
    "testing"
    "time"
)

func Now() string {
    return time.Now().Format("2015-07-25 23:02:00")
}

func TestNotErr(t *testing.T) {
    Convey("should not err", t, func() {

        err, idgen := newIdGen(1)
        if err != nil {
            t.Fatal("can not initialize")
        }

        for i := 0; i < 10; i++ {
            err, _ := idgen.NewId()
            So(err, ShouldBeNil)
        }
    })

}

func TestContainsMachineId(t *testing.T) {
    Convey("generated id should contains the `workerId`", t, func() {

        var workerId int
        for workerId = 0; workerId < 1024; workerId++ {
            err, idgen := newIdGen(workerId)

            if err != nil {
                t.Fatal("can not initialize")
            }

            for i := 0; i < 1; i++ {
                _, newId := idgen.NewId()
                newId2 := uint(newId << 42)
                newId3 := uint(newId2 >> 54)

                So(newId3, ShouldEqual, workerId)
            }
        }
    })
}

func TestMachineId(t *testing.T) {
    Convey("method 'MachineId' should return the right workerId", t, func() {

        var workerId int
        for workerId = 0; workerId < 1024; workerId++ {

            err, idgen := newIdGen(workerId)

            if err != nil {
                t.Fatal("can not initialize")
            }

            for i := 0; i < 1; i++ {
                _, newId := idgen.NewId()

                wId := idgen.MachineId(newId)
                So(wId, ShouldEqual, workerId)
            }
        }
    })
}
