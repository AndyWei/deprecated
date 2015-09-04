//
//  JYMessageDateFormatter.m
//  joyyios
//
//  Created by Ping Yang on 9/4/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYMessageDateFormatter.h"

@interface JYMessageDateFormatter ()
@end

@implementation JYMessageDateFormatter

+ (JYMessageDateFormatter *)sharedInstance
{
    static JYMessageDateFormatter *_sharedInstance = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedInstance = [JYMessageDateFormatter new];
        _sharedInstance.locale = [NSLocale currentLocale];
    });

    return _sharedInstance;
}

- (NSString *)autoStringFromDate:(NSDate *)date
{
    NSDate *today = [NSDate date];
    NSDateComponents *offsetComponents = [self.calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:today];
    NSDate *midnight = [self.calendar dateFromComponents:offsetComponents];

    // check if date is within today
    NSComparisonResult result = [date compare:midnight];
    if (result == NSOrderedDescending)
    {
        // 11:30 am
        self.dateStyle = NSDateFormatterNoStyle;
        self.timeStyle = NSDateFormatterShortStyle;
        return [[self stringFromDate:date] lowercaseString];
    }

    self.dateStyle = NSDateFormatterShortStyle;
    self.timeStyle = NSDateFormatterNoStyle;
    return [self stringFromDate:date];
}

@end
