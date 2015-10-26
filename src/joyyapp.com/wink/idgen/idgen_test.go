package idgen

import (
    "github.com/stretchr/testify/assert"
    "testing"
    "time"
)

func Now() string {
    return time.Now().Format("2015-07-25 23:02:00")
}

func TestNotErr(t *testing.T) {
    assert := assert.New(t)

    err, idgen := newIdGenerator(1)
    assert.Nil(err)

    for i := 0; i < 10; i++ {
        err, _ := idgen.newId()
        assert.Nil(err)
    }
}

func TestContainsMachineId(t *testing.T) {
    assert := assert.New(t)

    var workerId int
    for workerId = 0; workerId < 1024; workerId++ {
        err, idgen := newIdGenerator(workerId)

        assert.Nil(err)

        for i := 0; i < 1; i++ {
            _, newId := idgen.newId()
            newId2 := uint(newId << 42)
            machineId := uint(newId2 >> 54)
            assert.Equal(uint(workerId), machineId, "id should contain worker id")
        }
    }
}

func TestMachineId(t *testing.T) {
    assert := assert.New(t)

    var workerId int
    for workerId = 0; workerId < 1024; workerId++ {

        err, idgen := newIdGenerator(workerId)

        assert.Nil(err)

        for i := 0; i < 1; i++ {
            _, newId := idgen.newId()

            machineId := idgen.MachineId(newId)
            assert.Equal(int64(workerId), machineId, "machineId should equal to the workerId field")
        }
    }

}
