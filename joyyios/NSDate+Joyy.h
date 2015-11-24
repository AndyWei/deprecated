//
//  NSDate+Joyy.h
//  joyyios
//
//  Created by Ping Yang on 11/15/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@interface NSDate (Joyy)

+ (NSNumber *)idOfNow;
+ (NSNumber *)minIdWithOffsetInDays:(NSInteger)days;
+ (NSNumber *)minIdOfDay:(NSDate *)date;
+ (NSDate *)dateOfId:(NSNumber *)objId;

- (NSNumber *)joyyDay;
- (NSString *)ageString;
@end
