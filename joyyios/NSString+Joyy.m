//
//  NSString+Joyy.m
//  joyyios
//
//  Created by Ping Yang on 4/12/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "NSString+Joyy.h"

@implementation NSString (Joyy)

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

@end
