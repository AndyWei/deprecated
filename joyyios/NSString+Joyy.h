//
//  NSString+Joyy.h
//  joyyios
//
//  Created by Ping Yang on 4/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@interface NSString (Joyy)

+ (NSString *)agoStringForTimeInterval:(NSTimeInterval)interval;
+ (NSString *)apiURLWithPath:(NSString *)path;
+ (NSString *)dialingCodeForCountryCode:(NSString *)countryCode;

- (BOOL)isInvisible;
- (BOOL)isValidEmail;
- (BOOL)onlyContainsDigits;
- (BOOL)onlyContainsAlphanumericUnderscore; // A-Z, a-z, 0-9, _

- (NSString *)reversedString;
- (NSString *)messageDisplayString;
- (NSString *)messageMediaURL;
- (NSString *)pureNumberString;
- (NSNumber *)uint64Number;
- (uint64_t)uint64Value;


@end
