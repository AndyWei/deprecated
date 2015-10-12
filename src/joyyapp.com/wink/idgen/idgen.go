// Flake generates unique identifiers that are roughly sortable by time. Flake can
// run on a cluster of machines and still generate unique IDs without requiring
// machine coordination.
//
// A Flake ID is a 64-bit integer will the following components:
//  - 42 bits is the timestamp with millisecond precision
//  - 10 bits is the machine id
//  - 12 bits is an auto-incrementing sequence for ID requests within the same millisecond
//
// Note: In order to make a millisecond timestamp fit within 41 bits, a custom epoch of "01 Jan 2015 00:00:00 GMT" is used.

package idgen

import (
    "errors"
    "fmt"
    "sync"
    "time"
)

const (
    idgenEpoch         = int64(1420070400000) // 01 Jan 2015 00:00:00 GMT
    machineIdBits      = uint(10)
    maxMachineId       = -1 ^ (-1 << machineIdBits) //1023
    sequenceBits       = uint(12)
    machineIdShift     = sequenceBits                 //12
    timestampLeftShift = sequenceBits + machineIdBits //22
    sequenceMask       = -1 ^ (-1 << sequenceBits)    //4095
)

/**
 * 42 bits timestamp + 10 bits machineId + 12 bits sequence
 * Note: 对系统时间的依赖性非常强，一旦开启使用，需要关闭ntp的时间同步功能，或者当检测到ntp时间调整后，拒绝分配id
 *
 */
type IdGenerator struct {
    sequence      int64
    lastTimestamp int64
    machineId     int64
    mutex         *sync.Mutex
}

func SharedIdGenerator(machineId int64) (error, *IdGenerator) {
    generator := &IdGenerator{}
    if machineId > maxMachineId || machineId < 0 {
        return errors.New(fmt.Sprintf("illegal machine id: %d. A machine id must be in [0, 1023]", machineId)), nil
    }

    generator.machineId = machineId
    generator.lastTimestamp = -1
    generator.sequence = 0
    generator.mutex = &sync.Mutex{}

    return nil, generator
}

func timeInMillis() int64 {
    return int64(time.Nanosecond) * time.Now().UnixNano() / int64(time.Millisecond)
}

func tilNextMillis(lastTimestamp int64) int64 {
    timestamp := timeInMillis()
    for timestamp <= lastTimestamp {
        timestamp = timeInMillis()
    }
    return timestamp
}

func (id *IdGenerator) NextId() (error, int64) {
    id.mutex.Lock()
    defer id.mutex.Unlock()

    timestamp := timeInMillis()
    if timestamp < id.lastTimestamp {
        return errors.New(fmt.Sprintf("Clock moved backwards.Refusing to generate id for %d milliseconds", id.lastTimestamp-timestamp)), 0
    }

    if id.lastTimestamp == timestamp {
        id.sequence = (id.sequence + 1) & sequenceMask
        if id.sequence == 0 {
            timestamp = tilNextMillis(id.lastTimestamp)
        }
    } else {
        id.sequence = 0
    }
    id.lastTimestamp = timestamp
    return nil, ((timestamp - idgenEpoch) << timestampLeftShift) | (id.machineId << machineIdShift) | id.sequence
}

// Return which machine generated the given id
func (id *IdGenerator) MachineId(genId int64) int64 {
    machineId := uint(uint(genId<<42) >> 54)
    return int64(machineId)
}
