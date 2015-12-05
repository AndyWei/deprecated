//
//  JYComment.m
//  joyyios
//
//  Created by Ping Yang on 5/24/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYComment.h"
#import "JYFriendManager.h"

@interface JYComment ()
@property(nonatomic) NSString *displayText;
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
             @"content": @"content",
             @"displayText": [NSNull null]
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

- (NSString *)displayText
{
    if (!_displayText)
    {
        JYFriend *owner = [[JYFriendManager sharedInstance] friendOfId:self.ownerId];
        JYFriend *replyTo = ([self.replyToId unsignedLongLongValue] == 0) ? nil: [[JYFriendManager sharedInstance] friendOfId:self.replyToId];
        NSString *replyText = NSLocalizedString(@"reply", nil);
        if (replyTo)
        {
            _displayText = [NSString stringWithFormat:@"%@ %@ %@: %@", owner.username, replyText, replyTo.username, self.content];
        }
        else
        {
            _displayText = [NSString stringWithFormat:@"%@: %@", owner.username, self.content];
        }
    }
    return _displayText;
}

@end
