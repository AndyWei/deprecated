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

- (instancetype)initWithCommentId:(NSNumber *)commentId
{
    if (self = [super init])
    {
        _commentId = commentId;
    }
    return self;
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

- (BOOL)hasSameIdWith:(JYComment *)comment
{
    if (!comment || !comment.commentId)
    {
        return NO;
    }
    return ([self.commentId unsignedLongLongValue] == [comment.commentId unsignedLongLongValue]);
}

- (BOOL)isAntiComment
{
    return [self.content hasPrefix:@":anti_comment"];
}

- (BOOL)isLike
{
    return [kLikeText isEqualToString:self.content];
}

- (BOOL)isMine
{
    return ([[JYCredential current].userId unsignedLongLongValue] == [self.ownerId unsignedLongLongValue]);
}

// The anti comment id is inside the comment content, in form of "anti_comment:[ANTI_COMMENT_ID]"
- (NSNumber *)antiCommentId
{
    if (![self isAntiComment])
    {
        return nil;
    }

    NSRange range1 = [self.content rangeOfString:@"["];
    NSString  *temp=[self.content substringFromIndex:range1.location + 1];
    NSRange range2 = [temp rangeOfString:@"]"];

    NSString *idString = [temp substringWithRange:NSMakeRange(0, range2.location)];

    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    return [nf numberFromString:idString];
}

@end
