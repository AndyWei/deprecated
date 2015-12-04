//
//  JYPost.m
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFilename.h"
#import "JYComment.h"
#import "JYPost.h"


@interface JYPost ()
@property(nonatomic) NSString *caption;
@property(nonatomic) NSString *URL;
@end

@implementation JYPost

#pragma mark - MTLJSONSerializing methods

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"postId": @"postid",
             @"ownerId": @"ownerid",
             @"shortURL": @"url",
             @"caption": @"caption",
             };
}

#pragma mark - MTLFMDBSerializing methods

+ (NSDictionary *)FMDBColumnsByPropertyKey
{
    return @{
             @"postId": @"id",
             @"ownerId": @"ownerid",
             @"shortURL": @"url",
             @"caption": @"caption",
             @"URL": [NSNull null],
             @"commentList": [NSNull null],
             @"localImage": [NSNull null]
             };
}

+ (NSArray *)FMDBPrimaryKeys
{
    return @[@"id"];
}

+ (NSString *)FMDBTableName
{
    return @"post";
}

#pragma mark - properties

- (NSString *)caption
{
    if ([kDummyCaptionText isEqualToString:_caption])
    {
        _caption = @"";
    }

    return _caption;
}

- (NSString *)URL
{
    if (!_URL)
    {
        NSArray *array = [_shortURL componentsSeparatedByString:@":"];

        if ([array count] != 2)
        {
            NSLog(@"Illegal shortURL: %@", _shortURL);
            return nil;
        }

        NSString *region = array[0];
        NSString *prefix = [[JYFilename sharedInstance] postURLPrefixOfRegion:region];
        NSString *filename = array[1];
        _URL = [prefix stringByAppendingString:filename];
    }
    return _URL;
}

- (uint64_t)timestamp
{
    uint64_t postid = [self.postId unsignedLongLongValue];
    return (postid >> 32);
}

- (BOOL)isLikedByMe
{
    uint64_t myUserid = [[JYCredential current].userId unsignedLongLongValue];
    for (JYComment *comment in self.commentList)
    {
        uint64_t ownerid = [comment.ownerId unsignedLongLongValue];
        if (ownerid == myUserid && [comment isLike])
        {
            return YES;
        }
    }
    return NO;
}

@end
