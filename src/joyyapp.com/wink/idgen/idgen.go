/*
 * idgen.go
 * Idgen generates unique identifiers that are roughly sortable by time.
 *
 * An ID is a 64-bit integer will the following components:
 *  - 42 bits is the timestamp with millisecond precision
 *  - 10 bits is the machine id
 *  - 12 bits is an auto-incrementing sequence for ID requests within the same millisecond
 *
 * Note: In order to make a millisecond timestamp fit within 41 bits, a custom epoch of "01 Jan 2015 00:00:00 GMT" is used.
 *
 * Copyright (c) 2015 Joyy Inc. All rights reserved.
 */

package idgen

import (
    "errors"
    "fmt"
    . "github.com/spf13/viper"
    "log"
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

/*
 * 42 bits timestamp + 10 bits machineId + 12 bits sequence
 * Note: 对系统时间的依赖性非常强，一旦开启使用，需要关闭ntp的时间同步功能，或者当检测到ntp时间调整后，拒绝分配id
 *
 */
type IdGen struct {
    sequence      int64
    lastTimestamp int64
    machineId     int64
    mutex         *sync.Mutex
}

var sharedInstance *IdGen = nil

func panicOnError(err error) {
    if err != nil {
        log.Panic(err)
    }
}

func init() {

    SetConfigName("config")
    SetConfigType("toml")
    AddConfigPath("/etc/wink/")
    err := ReadInConfig()
    panicOnError(err)

    machineId := GetInt("idgen.machine_id")

    err, instance := newIdGen(machineId)
    sharedInstance = instance
    panicOnError(err)
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

func newIdGen(machineId int) (error, *IdGen) {
    generator := &IdGen{}
    if machineId > maxMachineId || machineId < 0 {
        return errors.New(fmt.Sprintf("illegal machine id: %d. A machine id must be in [0, 1023]", machineId)), nil
    }

    generator.machineId = int64(machineId)
    generator.lastTimestamp = -1
    generator.sequence = 0
    generator.mutex = &sync.Mutex{}

    return nil, generator
}

/*
 * Public functions
 */

func SharedInstance() *IdGen {
    return sharedInstance
}

func (id *IdGen) NewId() (error, int64) {
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
func (id *IdGen) MachineId(genId int64) int64 {
    machineId := uint(uint(genId<<42) >> 54)
    return int64(machineId)
}
