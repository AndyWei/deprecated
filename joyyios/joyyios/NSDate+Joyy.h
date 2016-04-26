//
//  NSDate+Joyy.h
//  joyyios
//
//  Created by Ping Yang on 11/15/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@interface NSDate (Joyy)

+ (NSDate *)dateOfId:(NSNumber *)objId;
+ (NSDate *)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;

- (NSNumber *)currentId;
- (NSNumber *)minId;
- (NSString *)ageString;
- (NSString *)localeStringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle;

@end
