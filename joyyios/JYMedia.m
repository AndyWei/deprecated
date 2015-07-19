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
            self.localImage = nil;
            self.mediaId = [[dict objectForKey:@"id"] unsignedIntegerValue];
            self.pathVersion = [[dict objectForKey:@"path_version"] unsignedIntegerValue];
            self.type = [[dict objectForKey:@"media_type"] unsignedIntegerValue];
            self.ownerId = [[dict objectForKey:@"owner_id"] unsignedIntegerValue];

            self.filename = [dict objectForKey:@"filename"];
            self.caption = [dict objectForKey:@"caption"];
        }
    }
    return self;
}

- (instancetype)initWithLocalImage:(UIImage *)image;
{
    self = [super init];
    if (self)
    {
        self.localImage = image;
        self.mediaId = 0;
        self.pathVersion = 0;
        self.type = JYMediaTypeImage;
        self.ownerId = [JYUser currentUser].userId;

        self.filename = @"";
        self.caption = @"local";
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
    switch (self.pathVersion)
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
@end
