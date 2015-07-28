//
//  JYMedia.m
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYMedia.h"
#import "JYUser.h"

@interface JYMedia ()

@end


@implementation JYMedia

+ (NSString *)newFilename
{
    NSString *first = [[JYUser currentUser].name substringToIndex:1];  // "j" for jack

    u_int32_t rand = arc4random_uniform(10000);                        // 176
    NSString *randString = [NSString stringWithFormat:@"%04d", rand];  // "0176"

    NSString *timestamp = [JYMedia _timeInMiliSeconds];                // 458354045799

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
            _isLiked = NO;

            _filename = [dict objectForKey:@"filename"];
            _caption = [dict objectForKey:@"caption"];

            _mediaId = [dict unsignedIntegerValueForKey:@"id"];
            _urlVersion = [dict unsignedIntegerValueForKey:@"uv"];
            _type = [dict unsignedIntegerValueForKey:@"type"];
            _ownerId = [dict unsignedIntegerValueForKey:@"owner"];
            _likeCount = [dict unsignedIntegerValueForKey:@"likes"];
            _commentCount = [dict unsignedIntegerValueForKey:@"comments"];
            _timestamp = [dict unsignedIntegerValueForKey:@"ct"];
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

        _mediaId = 0;
        _urlVersion = 0;
        _type = JYMediaTypeImage;
        _ownerId = [JYUser currentUser].userId;
        _likeCount = 0;
        _commentCount = 0;
    }
    return self;
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
        case JYMediaTypeImage:
            break;
        case JYMediaTypeVideo:
            // str = @".mp4"
            break;
        default:
            break;
    }
    return str;
}

- (void)setBrief:(NSDictionary *)brief
{
    if (!brief)
    {
        return;
    }

    _commentList = [brief objectForKey:@"comment_list"];
}

@end
