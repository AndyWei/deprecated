//
//  JYDay.h
//  joyyios
//
//  Created by Ping Yang on 12/17/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@interface JYDay : NSObject

- (instancetype)initWithDate:(NSDate *)date;
- (instancetype)prev;
- (instancetype)next;

@property (nonatomic) NSDate *date;
@property (nonatomic) uint64_t value;

@end
