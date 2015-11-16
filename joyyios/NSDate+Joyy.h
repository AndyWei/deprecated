//
//  NSDate+Joyy.h
//  joyyios
//
//  Created by Ping Yang on 11/15/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@interface NSDate (Joyy)

+ (uint64_t)idOfNow;
+ (uint64_t)minIdWithOffsetInDays:(uint64_t)days;
+ (uint64_t)minIdOfDay:(NSDate *)date;
+ (NSDate *)dateOfId:(uint64_t)objId;

- (uint64_t)joyyDay;

@end
