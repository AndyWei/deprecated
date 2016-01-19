//
//  JYInvite.m
//  joyyios
//
//  Created by Ping Yang on 1/16/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "JYInvite.h"

@implementation JYInvite

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"inviteId": @"id",
             @"userId": @"fid",
             @"username": @"fname",
             @"yrsNumber": @"fyrs"
             };
}

#pragma mark - MTLFMDBSerializing methods

+ (NSDictionary *)FMDBColumnsByPropertyKey
{
    return @{
             @"inviteId": @"id",
             @"userId": @"userid",
             @"username": @"username",
             @"yrsNumber": @"yrs",
             @"phoneNumber": @"phone",
             @"bio": [NSNull null],
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
    return @"invite";
}

@end
