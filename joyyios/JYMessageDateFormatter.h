//
//  JYMessageDateFormatter.h
//  joyyios
//
//  Created by Ping Yang on 9/4/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@interface JYMessageDateFormatter : NSDateFormatter

+ (JYMessageDateFormatter *)sharedInstance;

- (NSString *)autoStringFromDate:(NSDate *)date;
- (NSString *)timestampForDate:(NSDate *)date;
@end
