//
//  JYComment.m
//  joyyios
//
//  Created by Ping Yang on 5/24/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYComment.h"
#import "JYDataStore.h"

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

- (NSString *)displayText
{
    if (!_displayText)
    {
        NSString *username = [[JYDataStore sharedInstance] usernameOfId:self.ownerId];
        NSString *replyToUser = (self.replyToId == 0) ? nil: [[JYDataStore sharedInstance] usernameOfId:self.replyToId];
        NSString *reply = NSLocalizedString(@"reply", nil);
        if (replyToUser)
        {
            _displayText = [NSString stringWithFormat:@"%@ %@ %@: %@", username, reply, replyToUser, self.content];
        }
        else
        {
            _displayText = [NSString stringWithFormat:@"%@: %@", username, self.content];
        }

    }
    return _displayText;
}

@end
