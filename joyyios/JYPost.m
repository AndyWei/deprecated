//
//  JYPost.m
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <YTKKeyValueStore/YTKKeyValueStore.h>

#import "JYPost.h"

@interface JYPost ()
@end

@implementation JYPost

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        if (dict)
        {
            _filename = [dict objectForKey:@"filename"];
            _postId = [dict unsignedIntegerValueForKey:@"id"];
            _ownerId = [dict unsignedIntegerValueForKey:@"owner"];
            _likeCount = [dict unsignedIntegerValueForKey:@"likes"];
            _commentCount = [dict unsignedIntegerValueForKey:@"comments"];
            _timestamp = [dict unsignedIntegerValueForKey:@"ct"];
            _isLiked = [self _isInLikedStore];

            _caption = [dict objectForKey:@"caption"];
            if ([kDummyCaptionText isEqualToString:_caption])
            {
                _caption = @"";
            }
        }
    }
    return self;
}

- (void)setIsLiked:(BOOL)isLiked
{
    if (isLiked)
    {
        NSDictionary *value = @{ @"personId": [JYCredential currentCredential].idString };
        [[JYDataStore sharedInstance].store putObject:value withId:self.idString intoTable:kTableNameLikedPost];
    }

    _isLiked = isLiked;
}

- (BOOL)_isInLikedStore
{
    NSDictionary *liked = [[JYDataStore sharedInstance].store getObjectById:self.idString fromTable:kTableNameLikedPost];
    if (!liked)
    {
        return NO;
    }

    NSUInteger likedByPerson = [liked unsignedIntegerValueForKey:@"personId"];
    return (likedByPerson == [JYCredential currentCredential].userId);
}

- (NSString *)idString
{
    return [NSString stringWithFormat:@"%tu", self.postId];
}

- (NSString *)url
{
    return [NSString stringWithFormat:@"%@%@", kURLPostBase, self.filename];
}

@end
