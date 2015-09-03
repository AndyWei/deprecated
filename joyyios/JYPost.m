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

static NSString *const kLikedPostTable = @"liked_post";

@implementation JYPost

+ (YTKKeyValueStore *)sharedKVStore;
{
    static YTKKeyValueStore *_sharedKVStore = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedKVStore = [[YTKKeyValueStore alloc] initDBWithName:@"joyy_kv.db"];
        [_sharedKVStore createTableWithName:kLikedPostTable];
    });

    return _sharedKVStore;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        if (dict)
        {
            _localImage = nil;

            _filename = [dict objectForKey:@"filename"];
            _caption = [dict objectForKey:@"caption"];

            _postId = [dict unsignedIntegerValueForKey:@"id"];
            _urlVersion = [dict unsignedIntegerValueForKey:@"uv"];
            _ownerId = [dict unsignedIntegerValueForKey:@"owner"];
            _likeCount = [dict unsignedIntegerValueForKey:@"likes"];
            _commentCount = [dict unsignedIntegerValueForKey:@"comments"];
            _timestamp = [dict unsignedIntegerValueForKey:@"ct"];
            _isLiked = [self _isInLikedStore];
        }
    }
    return self;
}

- (instancetype)initWithLocalImage:(UIImage *)image;
{
    self = [super init];
    if (self)
    {
        _localImage = image;
        _isLiked = NO;

        _filename = @"";
        _caption = @"local";

        _postId = 0;
        _urlVersion = 0;
        _ownerId = [JYCredential current].personId;
        _likeCount = 0;
        _commentCount = 0;
    }
    return self;
}

- (void)setIsLiked:(BOOL)isLiked
{
    if (isLiked)
    {
        NSDictionary *value = @{ @"personId": [JYCredential current].idString };
        [[JYPost sharedKVStore] putObject:value withId:self.idString intoTable:kLikedPostTable];
    }

    _isLiked = isLiked;
}

- (BOOL)_isInLikedStore
{
    NSDictionary *liked = [[JYPost sharedKVStore] getObjectById:self.idString fromTable:kLikedPostTable];
    if (!liked)
    {
        return NO;
    }

    NSUInteger likedByPerson = [liked unsignedIntegerValueForKey:@"personId"];
    return (likedByPerson == [JYCredential current].personId);
}

- (NSString *)idString
{
    return [NSString stringWithFormat:@"%tu", self.postId];
}

- (NSString *)url
{
    if (self.localImage)
    {
        return nil;
    }

    return [NSString stringWithFormat:@"%@%@", [self baseURL], self.filename];
}

- (NSString *)baseURL
{
//    NSString *url = @"https://masquerade.joyy.s3.amazonaws.com/";
    NSString *url = @"https://s3.amazonaws.com/masquerade.joyy/";

    switch (self.urlVersion)
    {
        case 0:
            break;
        case 1:
            // url = ....
            break;
        default:
            break;
    }
    return url;
}

@end
