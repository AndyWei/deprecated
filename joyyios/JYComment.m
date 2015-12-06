//
//  JYComment.m
//  joyyios
//
//  Created by Ping Yang on 5/24/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYComment.h"

@interface JYComment ()
@end

@implementation JYComment

#pragma mark - MTLJSONSerializing methods

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"commentId": @"commentid",
             @"ownerId": @"ownerid",
             @"postId": @"postid",
             @"replyToId": @"replytoid",
             @"content": @"content"
             };
}

#pragma mark - MTLFMDBSerializing methods

+ (NSDictionary *)FMDBColumnsByPropertyKey
{
    return @{
             @"commentId": @"id",
             @"ownerId": @"ownerid",
             @"postId": @"postid",
             @"replyToId": @"replytoid",
             @"content": @"content"
             };
}

+ (NSArray *)FMDBPrimaryKeys
{
    return @[@"id"];
}

+ (NSString *)FMDBTableName
{
    return @"comment";
}

- (instancetype)initWithOwnerId:(NSNumber *)ownerid content:(NSString *)content
{
    if (self = [super init])
    {
        _ownerId = ownerid;
        _content = [content copy];
    }
    return self;
}

- (BOOL)isLike
{
    return [kLikeText isEqualToString:self.content];
}

@end
