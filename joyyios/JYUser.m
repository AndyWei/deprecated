//
//  JYUser.m
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFilename.h"
#import "JYYRS.h"
#import "NSNumber+Joyy.h"

@interface JYUser ()
@property (nonatomic) JYYRS *yrs;
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
             @"avatarImage": [NSNull null],
             @"avatarThumbnailImage": [NSNull null],
             @"yrs": [NSNull null]
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

- (JYYRS *)yrs
{
    if (!_yrs)
    {
        _yrs = [JYYRS yrsWithValue:[self.yrsNumber unsignedLongLongValue]];
    }
    return _yrs;
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
        NSInteger age = year - self.yrs.yob;
        _age = [NSString stringWithFormat:@"%ld", (long)age];
    }
    return _age;
}

- (NSString *)mediaURLPrefix
{
    NSString *region = [NSString stringWithFormat:@"%lu", (unsigned long)self.yrs.region];
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
    NSString *version = [NSString stringWithFormat:@"%lu", (unsigned long)self.yrs.version];
    NSString *filename = [NSString stringWithFormat:@"%@_%@.jpg", [self reversedIdString], version];
    return filename;
}

- (NSString *)avatarThumbnailFilename
{
    NSString *version = [NSString stringWithFormat:@"%lu", (unsigned long)self.yrs.version];
    NSString *filename = [NSString stringWithFormat:@"%@_%@_t.jpg", [self reversedIdString], version];
    return filename;
}

- (NSString *)nextAvatarFilename
{
    NSString *version = [NSString stringWithFormat:@"%lu", (unsigned long)[self.yrs nextVersion]];
    NSString *filename = [NSString stringWithFormat:@"%@_%@.jpg", [self reversedIdString], version];
    return filename;
}

- (NSString *)nextAvatarThumbnailFilename
{
    NSString *version = [NSString stringWithFormat:@"%lu", (unsigned long)[self.yrs nextVersion]];

    NSString *filename = [NSString stringWithFormat:@"%@_%@_t.jpg", [self reversedIdString], version];
    return filename;
}

- (void)setYrsNumber:(NSNumber *)yrsNumber
{
    _yrsNumber = yrsNumber;

    // clear those properties is to force they are re-generated from the new yrs value
    _yrs = nil;
    _avatarURL = nil;
    _avatarThumbnailURL = nil;
}

- (NSString *)reversedIdString
{
    NSString *idString = [self.userId uint64String];
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
    switch (self.yrs.sex)
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
