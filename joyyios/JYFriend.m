//
//  JYFriend.m
//  joyyios
//
//  Created by Ping Yang on 11/29/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYFriend.h"

@implementation JYFriend

#pragma mark - MTLJSONSerializing methods

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"userId": @"fid",
             @"username": @"fname",
             @"yrsNumber": @"fyrs",
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
             @"bio": @"bio",
             @"isHit": [NSNull null],
             @"isInvited": [NSNull null],
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
    return @"friend";
}

#pragma mark

+ (instancetype)myself
{
    if ([JYCredential current].isInvalid)
    {
        return nil;
    }

    static JYFriend *_myself = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _myself = [JYFriend new];
        _myself.userId = [JYCredential current].userId;
        _myself.username = [JYCredential current].username;
        _myself.yrsNumber = [NSNumber numberWithUnsignedLongLong:[JYCredential current].yrsValue];
        _myself.phoneNumber = [[JYCredential current].phoneNumber uint64Number];
    });

    return _myself;
}

@end
