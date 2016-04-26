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

+ (NSDate *)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];

    [components setDay:day];
    [components setMonth:month];
    [components setYear:year];
    return [calendar dateFromComponents:components];
}

+ (NSDate *)beginningOfDate:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    return [calendar dateFromComponents:components];
}

+ (NSNumber *)idFromTimestamp:(uint64_t)timestamp
{
    uint64_t ms = timestamp - JOYY_EPOCH;
    uint64_t idValue = (ms << 22);
    return [NSNumber numberWithUnsignedLongLong:idValue];
}

+ (uint64_t)timestampFromId:(NSNumber *)objId
{
    uint64_t objIdValue = [objId unsignedLongLongValue];
    uint64_t ms = (objIdValue >> 22);
    uint64_t timestamp = ms + JOYY_EPOCH;
    return timestamp;
}

+ (NSDate *)dateOfId:(NSNumber *)objId
{
    uint64_t timestamp = [NSDate timestampFromId:objId];
    NSTimeInterval ti = (CGFloat)timestamp / 1000.0;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:ti];
    return date;
}

- (NSNumber *)currentId
{
    uint64_t timestamp = (uint64_t)([self timeIntervalSince1970] * 1000);
    return [NSDate idFromTimestamp:timestamp];
}

- (NSNumber *)minId
{
    NSDate *midnight = [NSDate beginningOfDate:self];
    uint64_t timestamp = (uint64_t)([midnight timeIntervalSince1970] * 1000);
    return [NSDate idFromTimestamp:timestamp];
}

- (NSString *)ageString
{
    NSTimeInterval interval = (-1) * [self timeIntervalSinceNow];

    int numberOfDays = interval / 86400;
    if (numberOfDays > 0)
    {
        NSString *days = NSLocalizedString(@"d", nil);

        return [NSString stringWithFormat:@"%d%@", numberOfDays, days];
    }

    int numberOfHours = interval / 3600;
    if (numberOfHours > 0)
    {
        NSString *hours = NSLocalizedString(@"h", nil);

        return [NSString stringWithFormat:@"%d%@", numberOfHours, hours];
    }

    int numberOfMinutes = interval / 60;
    if (numberOfMinutes > 0)
    {
        NSString *minutes = NSLocalizedString(@"m", nil);

        return [NSString stringWithFormat:@"%d%@", numberOfMinutes, minutes];
    }

    int numberOfSeconds = (int)interval;
    NSString *seconds = NSLocalizedString(@"s", nil);
    return [NSString stringWithFormat:@"%d%@", numberOfSeconds, seconds];
}

- (NSString *)localeStringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:dateStyle];
    [dateFormatter setTimeStyle:timeStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    return[dateFormatter stringFromDate:self];
}
@end
