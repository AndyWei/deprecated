//
//  JYYRS.m
//  joyyios
//
//  Created by Ping Yang on 11/29/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYYRS.h"

@interface JYYRS ()
@end

@implementation JYYRS

+ (instancetype)yrsWithYob:(NSUInteger)yob region:(NSUInteger)region sex:(NSUInteger)sex
{
    return [[JYYRS alloc] initWithYob:yob region:region sex:sex];
}

+ (instancetype)yrsWithValue:(uint64_t)value
{
    return [[JYYRS alloc] initWithValue:value];
}

- (instancetype)initWithYob:(NSUInteger)yob region:(NSUInteger)region sex:(NSUInteger)sex
{
    self = [super init];
    if (self)
    {
        self.yob = yob;
        self.region = region;
        self.sex = sex;
        self.value = ((yob & 0xFFFF) << 16) | ((region & 0xFF) << 8) | (sex & 0xFF);
    }
    return self;
}

- (instancetype)initWithValue:(uint64_t)value
{
    self = [super init];
    if (self)
    {
        self.yob = (value & 0xFFFF) >> 16;
        self.region = (value & 0xFF00) >> 8;
        self.sex = value & 0xFF;
        self.value = value;
    }
    return self;
}

@end
