//
//  NSDictionary+Joyy.m
//  joyyios
//
//  Created by Ping Yang on 7/24/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "NSDictionary+Joyy.h"

@implementation NSDictionary (Joyy)

- (NSUInteger)unsignedIntegerValueForKey:(id)aKey
{
    id obj = [self objectForKey:aKey];
    return (obj == [NSNull null]) ? 0 : [(NSString *)obj unsignedIntegerValue];
}

@end
