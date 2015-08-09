//
//  JYPost.m
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <YTKKeyValueStore/YTKKeyValueStore.h>

#import "JYPost.h"
#import "JYUser.h"

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

+ (NSString *)newFilename
{
    NSString *first = [[JYUser currentUser].name substringToIndex:1];  // "j" for jack

    u_int32_t rand = arc4random_uniform(10000);                        // 176
    NSString *randString = [NSString stringWithFormat:@"%04d", rand];  // "0176"

    NSString *timestamp = [JYPost _timeInMiliSeconds];                // 458354045799

    return [NSString stringWithFormat:@"%@%@_%@", first, randString, timestamp]; // "j0176_458354045799"
}

+ (NSString *)_timeInMiliSeconds
{
    long long timestamp = [@(floor([NSDate timeIntervalSinceReferenceDate] * 1000)) longLongValue];
    return [NSString stringWithFormat:@"%lld",timestamp];
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
            _type = [dict unsignedIntegerValueForKey:@"type"];
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
        _type = JYPostTypeImage;
        _ownerId = [JYUser currentUser].userId;
        _likeCount = 0;
        _commentCount = 0;
    }
    return self;
}

- (void)setIsLiked:(BOOL)isLiked
{
    if (isLiked)
    {
        NSUInteger personId = [JYUser currentUser].userId;
        NSDictionary *value = @{ @"personId": @(personId)};
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
    return (likedByPerson == [JYUser currentUser].userId);
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

    return [NSString stringWithFormat:@"%@%@%@", [self baseURL], self.filename, [self suffix]];
}

- (NSString *)baseURL
{
    NSString *url = @"https://joyydev.s3.amazonaws.com/";
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

- (NSString *)suffix
{
    NSString *str = @".jpg";
    switch (self.type)
    {
        case JYPostTypeImage:
            break;
        case JYPostTypeVideo:
            // str = @".mp4"
            break;
        default:
            break;
    }
    return str;
}

@end
