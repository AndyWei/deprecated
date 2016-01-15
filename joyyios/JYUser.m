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
             @"yrsNumber": @"yrs",
             @"phoneNumber": @"phone",
             @"bio": @"bio"
             };
}

#pragma mark - MTLFMDBSerializing methods

+ (NSDictionary *)FMDBColumnsByPropertyKey
{
    return @{
             @"userId": @"id",
             @"username": @"username",
             @"yrsNumber": @"yrs",
             @"phoneNumber": @"phone",
             @"isHit": @"hit",
             @"isInvited": @"invited",
             @"bio": [NSNull null],
             @"avatarURL": [NSNull null],
             @"avatarThumbnailURL": [NSNull null],
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

- (NSString *)age
{
    if (self.yrsNumber == 0)
    {
        return nil;
    }

    if (!_age)
    {
        NSCalendar *gregorian = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        NSInteger year = [gregorian component:NSCalendarUnitYear fromDate:NSDate.date];
        JYYRS *yrs = [JYYRS yrsWithValue:[self.yrsNumber unsignedLongLongValue]];
        NSInteger age = year - yrs.yob;
        _age = [NSString stringWithFormat:@"%ld", (long)age];
    }
    return _age;
}

- (NSString *)mediaURLPrefix
{
    JYYRS *yrs = [JYYRS yrsWithValue:[self.yrsNumber unsignedLongLongValue]];
    NSString *region = [NSString stringWithFormat:@"%lu", (unsigned long)yrs.region];
    NSString *prefix = [[JYFilename sharedInstance] avatarURLPrefixOfRegion:region];
    return prefix;
}

- (NSURL *)avatarURL
{
    if (!_avatarURL)
    {
        NSString *str = [NSString stringWithFormat:@"%@%@", [self mediaURLPrefix], [self avatarFilename]];
        _avatarURL = [NSURL URLWithString:str];
    }
    return _avatarURL;
}

- (NSURL *)avatarThumbnailURL
{
    if (!_avatarThumbnailURL)
    {
        NSString *str = [NSString stringWithFormat:@"%@%@", [self mediaURLPrefix], [self avatarThumbnailFilename]];
        _avatarThumbnailURL = [NSURL URLWithString:str];
    }
    return _avatarThumbnailURL;
}

- (NSString *)avatarFilename
{
    JYYRS *yrs = [JYYRS yrsWithValue:[self.yrsNumber unsignedLongLongValue]];
    NSString *version = [NSString stringWithFormat:@"%lu", (unsigned long)yrs.version];
    NSString *filename = [NSString stringWithFormat:@"%@_%@.jpg", [self reversedIdString], version];
    return filename;
}

- (NSString *)avatarThumbnailFilename
{
    JYYRS *yrs = [JYYRS yrsWithValue:[self.yrsNumber unsignedLongLongValue]];
    NSString *version = [NSString stringWithFormat:@"%lu", (unsigned long)yrs.version];
    NSString *filename = [NSString stringWithFormat:@"%@_%@_t.jpg", [self reversedIdString], version];
    return filename;
}

- (NSString *)nextAvatarFilename
{
    JYYRS *yrs = [JYYRS yrsWithValue:[self.yrsNumber unsignedLongLongValue]];
    NSString *version = [NSString stringWithFormat:@"%lu", (unsigned long)[yrs nextVersion]];

    NSString *filename = [NSString stringWithFormat:@"%@_%@.jpg", [self reversedIdString], version];
    return filename;
}

- (NSString *)nextAvatarThumbnailFilename
{
    JYYRS *yrs = [JYYRS yrsWithValue:[self.yrsNumber unsignedLongLongValue]];
    NSString *version = [NSString stringWithFormat:@"%lu", (unsigned long)[yrs nextVersion]];

    NSString *filename = [NSString stringWithFormat:@"%@_%@_t.jpg", [self reversedIdString], version];
    return filename;
}

- (void)setYrsNumber:(NSNumber *)yrsNumber
{
    _yrsNumber = yrsNumber;

    // clear the old avatar URLs will force they are re-generated from the new yrs value
    _avatarURL = nil;
    _avatarThumbnailURL = nil;
}

- (NSString *)reversedIdString
{
    NSString *idString = [NSString stringWithFormat:@"%llu", [self.userId unsignedLongLongValue]];
    return [idString reversedString];
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
    JYYRS *yrs = [JYYRS yrsWithValue:[self.yrsNumber unsignedLongLongValue]];
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
