//
//  NSString+Joyy.m
//  joyyios
//
//  Created by Ping Yang on 4/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "NSString+Joyy.h"

@implementation NSString (Joyy)

+ (NSString *)agoStringForTimeInterval:(NSTimeInterval)interval
{
    NSString *ago = NSLocalizedString(@"ago", nil);
    int numberOfDays = interval / 86400;
    if (numberOfDays > 0)
    {
        NSString *days = (numberOfDays == 1) ? NSLocalizedString(@"day", nil) : NSLocalizedString(@"days", nil);

        return [NSString stringWithFormat:@"%d %@ %@", numberOfDays, days, ago];
    }

    int numberOfHours = interval / 3600;
    if (numberOfHours > 0)
    {
        NSString *hours = (numberOfHours == 1) ? NSLocalizedString(@"hour", nil) : NSLocalizedString(@"hours", nil);

        return [NSString stringWithFormat:@"%d %@ %@", numberOfHours, hours, ago];
    }

    int numberOfMinutes = interval / 60;
    if (numberOfMinutes > 0)
    {
        NSString *minutes = (numberOfMinutes == 1) ? NSLocalizedString(@"minute", nil) : NSLocalizedString(@"minutes", nil);

        return [NSString stringWithFormat:@"%d %@ %@", numberOfMinutes, minutes, ago];
    }

    int numberOfSeconds = (int)interval;
    NSString *seconds = (numberOfSeconds == 1) ? NSLocalizedString(@"second", nil) : NSLocalizedString(@"seconds", nil);
    return [NSString stringWithFormat:@"%d %@ %@", numberOfSeconds, seconds, ago];
}

+ (NSString *)apiURLWithPath:(NSString *)path
{
    return [NSString stringWithFormat:@"%@%@", kUrlAPIBase, path];
}

- (BOOL)isInvisible
{
    NSCharacterSet *whiteSpaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    return [[self stringByTrimmingCharactersInSet:whiteSpaceSet] length] == 0;
}

- (BOOL)isValidEmail
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}

- (NSUInteger)unsignedIntegerValue
{
    NSNumber *number = [NSNumber numberWithLongLong: self.longLongValue];
    return number.unsignedIntegerValue;
}

- (NSString *)personIdString
{
    NSArray *parts = [self componentsSeparatedByString:@"@"];
    return parts[0];
}

@end
