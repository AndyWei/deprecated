//
//  JYDay.m
//  joyyios
//
//  Created by Ping Yang on 12/17/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYDay.h"

@implementation JYDay

- (instancetype)initWithDate:(NSDate *)date
{
    if (self = [super init])
    {
        self.date = date;

        NSDateComponents *components = [[NSCalendar currentCalendar] components: NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
        uint64_t year = (uint64_t)[components year];
        uint64_t month = (uint64_t)[components month];
        uint64_t day = (uint64_t)[components day];

        self.value = ((year - 2000) * 10000) + (month * 100) + day;
    }
    return self;
}

- (instancetype)prev
{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setDay:-1];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *newDate = [calendar dateByAddingComponents:dateComponents toDate:self.date options:0];

    return [[JYDay alloc] initWithDate:newDate];
}

- (instancetype)next
{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setDay:1];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *newDate = [calendar dateByAddingComponents:dateComponents toDate:self.date options:0];

    return [[JYDay alloc] initWithDate:newDate];
}

@end
