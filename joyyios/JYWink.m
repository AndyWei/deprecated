//
//  JYWink.m
//  joyyios
//
//  Created by Ping Yang on 1/16/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "JYWink.h"

@implementation JYWink

#pragma mark - MTLJSONSerializing methods

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"winkId": @"id",
             @"userId": @"fid",
             @"username": @"fname",
             @"yrsNumber": @"fyrs"
             };
}

#pragma mark - MTLFMDBSerializing methods

+ (NSDictionary *)FMDBColumnsByPropertyKey
{
    return @{
             @"winkId": @"id",
             @"userId": @"userid",
             @"username": @"username",
             @"yrsNumber": @"yrs",
             @"phoneNumber": [NSNull null],
             @"bio": [NSNull null],
             @"isHit": [NSNull null],
             @"isInvited": [NSNull null],
             @"avatarURL": [NSNull null],
             @"avatarThumbnailURL": [NSNull null],
             @"sex": [NSNull null],
             @"age": [NSNull null],
             @"avatarImage": [NSNull null],
             @"avatarThumbnailImage": [NSNull null]
             };
}

+ (NSArray *)FMDBPrimaryKeys
{
    return @[@"id"];
}

+ (NSString *)FMDBTableName
{
    return @"wink";
}

@end
