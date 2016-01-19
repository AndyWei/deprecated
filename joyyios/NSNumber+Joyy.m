//
//  NSNumber+Joyy.m
//  joyyios
//
//  Created by Ping Yang on 1/16/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "NSNumber+Joyy.h"

@implementation NSNumber (Joyy)

- (NSNumber *)uint64Number
{
    uint64_t value = [self unsignedLongLongValue];
    return [NSNumber numberWithUnsignedLongLong:value];
}

@end
