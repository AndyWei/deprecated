//
//  JYYRS.h
//  joyyios
//
//  Created by Ping Yang on 11/29/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@interface JYYRS : NSObject

+ (instancetype)yrsWithYob:(NSUInteger)yob region:(NSUInteger)region sex:(NSUInteger)sex;
+ (instancetype)yrsWithValue:(uint64_t)value;

- (instancetype)initWithYob:(NSUInteger)yob region:(NSUInteger)region sex:(NSUInteger)sex;
- (instancetype)initWithValue:(uint64_t)value;

@property (nonatomic) NSUInteger yob;
@property (nonatomic) NSUInteger region;
@property (nonatomic) NSUInteger sex;
@property (nonatomic) uint64_t value;

@end
