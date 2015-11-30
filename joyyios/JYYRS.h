//
//  JYYRS.h
//  joyyios
//
//  Created by Ping Yang on 11/29/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@interface JYYRS : NSObject

+ (instancetype)yrsWithYob:(NSUInteger)yob region:(NSUInteger)region sex:(NSUInteger)sex;
+ (instancetype)yrsWithValue:(NSUInteger)value;

- (instancetype)initWithYob:(NSUInteger)yob region:(NSUInteger)region sex:(NSUInteger)sex;
- (instancetype)initWithValue:(NSUInteger)value;

@property (nonatomic) NSUInteger yob;
@property (nonatomic) NSUInteger region;
@property (nonatomic) NSUInteger sex;
@property (nonatomic) NSUInteger value;

@end
