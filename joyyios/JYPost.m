//
//  JYPost.m
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <YTKKeyValueStore/YTKKeyValueStore.h>

#import "JYFilename.h"
#import "JYPost.h"

@interface JYPost ()
@property(nonatomic) NSString *region;
@property(nonatomic) NSString *filename;
@property(nonatomic) NSString *url;
@property(nonatomic) NSString *idString;
@end

@implementation JYPost

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        if (dict)
        {
            _region   = [dict objectForKey:@"reg"];
            _filename = [dict objectForKey:@"fn"];
            _caption = [dict objectForKey:@"caption"];
            _postId       = [dict unsignedIntegerValueForKey:@"id"];
            _ownerId      = [dict unsignedIntegerValueForKey:@"owner"];
            _likeCount    = [dict unsignedIntegerValueForKey:@"lcnt"];
            _commentCount = [dict unsignedIntegerValueForKey:@"ccnt"];
            _timestamp    = [dict unsignedIntegerValueForKey:@"ct"];
            _isLiked = [self _isInLikedStore];

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
        NSDictionary *value = @{ @"personId": [JYCredential current].idString };
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
    return (likedByPerson == [JYCredential current].userId);
}

- (NSString *)idString
{
    if (!_idString)
    {
        _idString = [NSString stringWithFormat:@"%tu", self.postId];
    }
    return _idString;
}

- (NSString *)url
{
    if (!_url)
    {
        _url = [[JYFilename sharedInstance] urlForPostWithRegion:self.region filename:self.filename];
    }
    return _url;
}

@end
