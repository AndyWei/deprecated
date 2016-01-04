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

+ (instancetype)yrsWithVersion:(NSUInteger)version yob:(NSUInteger)yob region:(NSUInteger)region sex:(NSUInteger)sex
{
    return [[JYYRS alloc] initWithVersion:version yob:yob region:region sex:sex];
}

+ (instancetype)yrsWithValue:(uint64_t)value
{
    return [[JYYRS alloc] initWithValue:value];
}

- (instancetype)initWithVersion:(NSUInteger)version yob:(NSUInteger)yob region:(NSUInteger)region sex:(NSUInteger)sex
{
    self = [super init];
    if (self)
    {
        self.version = version;
        self.yob = yob;
        self.region = region;
        self.sex = sex;
        self.value = [self _valueWithVersion:version yob:yob region:region sex:sex];
    }
    return self;
}

- (instancetype)initWithValue:(uint64_t)value
{
    self = [super init];
    if (self)
    {
        self.version = (value >> 32) & 0xFFFF;
        self.yob = (value >> 16) & 0xFFFF;
        self.region = (value >> 8) & 0xFF;
        self.sex = value & 0xFF;
        self.value = value;
    }
    return self;
}

- (NSUInteger)nextVersion
{
    NSUInteger version = self.version + 1;
    return version & 0xFFFF; // bound version to 16 bits
}

- (void)increaseVersion
{
    self.version = [self nextVersion];
    self.value = [self _valueWithVersion:self.version yob:self.yob region:self.region sex:self.sex];
}

- (void)setVersion:(NSUInteger)version
{
    _version = version;
    self.value = [self _valueWithVersion:_version yob:_yob region:_region sex:_sex];
}

- (void)setYob:(NSUInteger)yob
{
    _yob = yob;
    self.value = [self _valueWithVersion:_version yob:_yob region:_region sex:_sex];
}

- (void)setSex:(NSUInteger)sex
{
    _sex = sex;
    self.value = [self _valueWithVersion:_version yob:_yob region:_region sex:_sex];
}

- (void)setRegion:(NSUInteger)region
{
    _region = region;
    self.value = [self _valueWithVersion:_version yob:_yob region:_region sex:_sex];
}

- (uint64_t)_valueWithVersion:(NSUInteger)version yob:(NSUInteger)yob region:(NSUInteger)region sex:(NSUInteger)sex
{
    uint64_t versionValue = (uint64_t)version;
    uint64_t value = ((versionValue & 0xFFFF) << 32) |
                     ((yob & 0xFFFF) << 16) |
                     ((region & 0xFF) << 8) |
                     (sex & 0xFF);
    return value;
}

@end
