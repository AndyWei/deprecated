//
//  JYUser.m
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
        NSString *region = [NSString stringWithFormat:@"%lu", (unsigned long)yrs.region];
        NSString *prefix = [[JYFilename sharedInstance] avatarURLPrefixOfRegion:region];

        NSString *filename = [self avatarFilename];
        _avatarURL = [NSString stringWithFormat:@"%@%@", prefix, filename];
    }
    return _avatarURL;
}

- (void)setYrsValue:(uint64_t)yrsValue
{
    _yrsValue = yrsValue;
    _avatarURL = nil; // clear the old avatar URL will force it's re-generated from the new yrs value
}

- (NSString *)reversedIdString
{
    NSString *idString = [NSString stringWithFormat:@"%llu", [self.userId unsignedLongLongValue]];
    return [idString reversedString];
}

- (NSString *)avatarFilename
{
    JYYRS *yrs = [JYYRS yrsWithValue:self.yrsValue];
    NSString *version = [NSString stringWithFormat:@"%lu", (unsigned long)yrs.version];
    NSString *filename = [NSString stringWithFormat:@"%@_%@.jpg", [self reversedIdString], version];
    return filename;
}

- (NSString *)nextS3Filename
{
    JYYRS *yrs = [JYYRS yrsWithValue:self.yrsValue];
    NSString *version = [NSString stringWithFormat:@"%lu", (unsigned long)[yrs nextVersion]];

    NSString *filename = [NSString stringWithFormat:@"%@_%@.jpg", [self reversedIdString], version];
    return filename;
}

- (NSString *)sex
{
    if (!_sex)
    {
        NSString *str = [self sexLongString];
        _sex = [str substringWithRange:NSMakeRange(0, 1)];
    }
    return _sex;
}

- (NSString *)sexLongString
{
    NSString *sex = NSLocalizedString(@"Other", nil);
    JYYRS *yrs = [JYYRS yrsWithValue:self.yrsValue];
    switch (yrs.sex)
    {
        case 0:
            sex = NSLocalizedString(@"Female", nil);
            break;
        case 1:
            sex = NSLocalizedString(@"Male", nil);
            break;
        default:
            break;
    }
    return sex;
}

@end
