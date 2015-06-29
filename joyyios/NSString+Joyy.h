//
//  NSString+Joyy.h
//  joyyios
//
//  Created by Ping Yang on 4/12/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@interface NSString (Joyy)

+ (NSString *)stringFromTimeInterval:(NSTimeInterval)interval;

- (BOOL)isValidEmail;
- (NSUInteger)unsignedIntegerValue;

@end
