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
             @"yrsValue": @"fyrs",
             @"bio": @"bio",
             @"phoneNumber": @"phone"
             };
}

#pragma mark - MTLFMDBSerializing methods

+ (NSDictionary *)FMDBColumnsByPropertyKey
{
    return @{
             @"userId": @"id",
             @"username": @"username",
             @"yrsValue": @"yrs",
             @"phoneNumber": @"phone",
             @"bio": @"bio",
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
    return @"friend";
}

@end
