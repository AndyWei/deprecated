/*
 * idgen.go
 * Idgen generates unique identifiers that are roughly sortable by time.
 *
 * An ID is a 64-bit integer will the following components:
 *  - 41 bits of timestamp with millisecond precision
 *  - 10 bits of machine id
 *  - 12 bits of auto-incrementing counter for ID requests within the same millisecond
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
    . "joyyapp.com/winkrock/util"
    "sync"
    "time"
)

const (
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

/*
 * Public functions
 */
func NewID() int64 {
    err, id := sharedInstance.newId()
    LogPanic(err)
    return id
}

// Return which machine generated the given id
func MachineId(id int64) int64 {
    machineId := uint(uint(id<<42) >> 54)
    return int64(machineId)
}

// Return the day of id generated date. eg, if the id is generated on 2015/10/28, then the return value should be 151028
func DayOf(id int64) int {
    t := TimeOf(id)
    return Day(t)
}

// Return the month of id generated date. eg, if the id is generated on 2015/10/28, then the return value should be 1510
func MonthOf(id int64) int {
    t := TimeOf(id)
    return Month(t)
}

func init() {

    SetConfigName("config")
    SetConfigType("toml")
    AddConfigPath("/etc/winkrock/")
    err := ReadInConfig()
    LogFatal(err)

    machineId := GetInt("idgen.machineID")

    err, instance := newIdGenerator(machineId)
    sharedInstance = instance
    LogFatal(err)
}

func tilNextMillis(lastTimestamp int64) int64 {
    timestamp := TimeInMillis()
    for timestamp <= lastTimestamp {
        timestamp = TimeInMillis()
    }
    return timestamp
}

func newIdGenerator(machineId int) (error, *IdGen) {
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

func (id *IdGen) newId() (error, int64) {
    id.mutex.Lock()
    defer id.mutex.Unlock()

    timestamp := TimeInMillis()
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
    return nil, ((timestamp - Epoch()) << timestampLeftShift) | (id.machineId << machineIdShift) | id.sequence
}

func TimeOf(id int64) time.Time {
    uid := uint64(id)
    timestamp := int64(uid >> 22)
    millis := timestamp + Epoch()
    secs := millis / 1000
    nsecs := (millis % 1000) * 1000
    return time.Unix(secs, nsecs)
}
