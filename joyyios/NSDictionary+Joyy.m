//
//  NSDictionary+Joyy.m
//  joyyios
//
//  Created by Ping Yang on 7/24/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "NSDictionary+Joyy.h"

@implementation NSDictionary (Joyy)

- (uint64_t)uint64ValueForKey:(id)key
{
    id obj = [self objectForKey:key];
    return (obj == [NSNull null]) ? 0 : [(NSString *)obj uint64Value];
}

@end
