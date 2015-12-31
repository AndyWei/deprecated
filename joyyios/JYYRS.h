//
//  JYYRS.h
//  joyyios
//
//  Created by Ping Yang on 11/29/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@interface JYYRS : NSObject

+ (instancetype)yrsWithVersion:(NSUInteger)version yob:(NSUInteger)yob region:(NSUInteger)region sex:(NSUInteger)sex;
+ (instancetype)yrsWithValue:(uint64_t)value;

- (instancetype)initWithVersion:(NSUInteger)version yob:(NSUInteger)yob region:(NSUInteger)region sex:(NSUInteger)sex;
- (instancetype)initWithValue:(uint64_t)value;

- (NSUInteger)nextVersion;

@property (nonatomic) NSUInteger version;
@property (nonatomic) NSUInteger yob;
@property (nonatomic) NSUInteger region;
@property (nonatomic) NSUInteger sex;
@property (nonatomic) uint64_t value;

@end
