//
//  NSString+Joyy.h
//  joyyios
//
//  Created by Ping Yang on 4/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@interface NSString (Joyy)

+ (NSString *)apiURLWithPath:(NSString *)path;
+ (NSString *)dialingCodeForCountryCode:(NSString *)countryCode;
+ (NSString *)base62String:(uint64_t)num;
+ (NSString *)stringWithTimeInterval:(NSTimeInterval)interval;
+ (NSString *)stringWithTimestampInMiliSeconds;

- (BOOL)isInvisible;
- (BOOL)isValidEmail;
- (BOOL)onlyContainsDigits;
- (BOOL)onlyContainsAlphanumericUnderscore; // A-Z, a-z, 0-9, _

- (NSString *)reversedString;
- (NSString *)pureNumberString;
- (NSNumber *)uint64Number;
- (uint64_t)uint64Value;


@end
