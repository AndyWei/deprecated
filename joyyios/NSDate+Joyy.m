//
//  NSDate+Joyy.m
//  joyyios
//
//  Created by Ping Yang on 11/15/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "NSDate+Joyy.h"

const uint64_t JOYY_EPOCH = 1420070400000; // 01 Jan 2015 00:00:00 GMT

@implementation NSDate (Joyy)

+ (NSDate *)beginningOfDay:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];
    return [calendar dateFromComponents:components];
}

+ (uint64_t)idFromTimestamp:(uint64_t)timestamp
{
    uint64_t ms = timestamp - JOYY_EPOCH;
    return (ms << 22);
}

+ (uint64_t)timestampFromId:(uint64_t)objId
{
    uint64_t ms = (objId >> 22);
    uint64_t timestamp = ms + JOYY_EPOCH;
    return timestamp;
}

+ (uint64_t)idOfNow
{
    uint64_t timestamp = (uint64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    return [NSDate idFromTimestamp:timestamp];
}

+ (uint64_t)minIdOfDay:(NSDate *)date
{
    NSDate *midnight = [NSDate beginningOfDay:date];
    uint64_t timestamp = (uint64_t)([midnight timeIntervalSince1970] * 1000);
    return [NSDate idFromTimestamp:timestamp];
}

+ (uint64_t)minIdWithOffsetInDays:(uint64_t)days
{
    NSDate *now = [NSDate date];
    NSDate *newDate = [now dateByAddingTimeInterval:60 * 60 * 24 * days];
    return [NSDate minIdOfDay:newDate];
}

+ (NSDate *)dateOfId:(uint64_t)objId
{
    uint64_t timestamp = [NSDate timestampFromId:objId];
    NSTimeInterval ti = (CGFloat)timestamp / 1000.0;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:ti];
    return date;
}

- (uint64_t)joyyDay
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self];
    uint64_t year = (uint64_t)[components year];
    uint64_t month = (uint64_t)[components month];
    uint64_t day = (uint64_t)[components day];

    return ((year - 2000) * 10000) + (month * 100) + day;
}

@end
