//
//  JYPerson.m
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFilename.h"
#import "JYYRS.h"

@interface JYUser ()
@end

@implementation JYUser

#pragma mark - MTLJSONSerializing methods

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"userId": @"userid",
             @"username": @"username",
             @"yrsValue": @"yrs",
             @"bio": @"bio"
             };
}

#pragma mark - MTLFMDBSerializing methods

+ (NSDictionary *)FMDBColumnsByPropertyKey
{
    return @{
             @"userId": @"id",
             @"username": @"username",
             @"yrsValue": @"yrs",
             @"bio": [NSNull null],
             @"avatarURL": [NSNull null],
             @"sex": [NSNull null],
             @"age": [NSNull null],
             @"avatarImage": [NSNull null]
             };
}

+ (NSArray *)FMDBPrimaryKeys
{
    return @[@"id"];
}

+ (NSString *)FMDBTableName
{
    return @"user";
}

#pragma mark - properties

- (NSString *)age
{
    if (self.yrsValue == 0)
    {
        return nil;
    }

    if (!_age)
    {
        NSCalendar *gregorian = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        NSInteger year = [gregorian component:NSCalendarUnitYear fromDate:NSDate.date];
        JYYRS *yrs = [JYYRS yrsWithValue:self.yrsValue];
        NSInteger age = year - yrs.yob;
        _age = [NSString stringWithFormat:@"%ld", (long)age];
    }
    return _age;
}

- (NSString *)avatarURL
{
    if (!_avatarURL)
    {
        JYYRS *yrs = [JYYRS yrsWithValue:self.yrsValue];
        NSString *region = [NSString stringWithFormat:@"%ld", (long)yrs.region];
        NSString *prefix = [[JYFilename sharedInstance] avatarURLPrefixOfRegion:region];
        uint64_t userid = [self.userId unsignedLongLongValue];
        NSString *filename = [NSString stringWithFormat:@"%llu.jpg", userid];
        _avatarURL = [prefix stringByAppendingString:filename];
    }
    return _avatarURL;
}

- (NSString *)sex
{
    if (!_sex)
    {
        JYYRS *yrs = [JYYRS yrsWithValue:self.yrsValue];
        switch (yrs.sex)
        {
            case 0:
                _sex = @"F";
                break;
            case 1:
                _sex = @"M";
                break;
            default:
                _sex = @"X";
                break;
        }
    }
    return _sex;
}

@end
