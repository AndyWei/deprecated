//
//  JoyyMonth.h
//  joyyios
//
//  Created by Ping Yang on 12/9/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@interface JYMonth : NSObject

- (instancetype)initWithDate:(NSDate *)date;
- (JYMonth *)prev;
- (JYMonth *)next;

@property (nonatomic) NSDate *date;
@property (nonatomic) uint64_t value;

@end
