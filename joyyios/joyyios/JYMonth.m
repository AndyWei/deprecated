//
//  JoyyMonth.m
//  joyyios
//
//  Created by Ping Yang on 12/9/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYMonth.h"

@implementation JYMonth

- (instancetype)initWithDate:(NSDate *)date
{
    if (self = [super init])
    {
        self.date = date;

        NSDateComponents *components = [[NSCalendar currentCalendar] components: NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
        uint64_t year = (uint64_t)[components year];
        uint64_t month = (uint64_t)[components month];
        self.value = ((year - 2000) * 100) + month;
    }
    return self;
}

- (instancetype)prev
{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setMonth:-1];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *newDate = [calendar dateByAddingComponents:dateComponents toDate:self.date options:0];

    return [[JYMonth alloc] initWithDate:newDate];
}

- (instancetype)next
{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setMonth:+1];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *newDate = [calendar dateByAddingComponents:dateComponents toDate:self.date options:0];

    return [[JYMonth alloc] initWithDate:newDate];
}

@end
