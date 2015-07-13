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
            self.userId = [[dict objectForKey:@"user_id"] unsignedIntegerValue];

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
        self.type = JYMediaTypePhoto;
        self.userId = [JYUser currentUser].userId;

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

    NSString *baseURL = @"https://joyydev.s3.amazonaws.com/";
    switch (self.pathVersion)
    {
        case 0:
            break;
        default:
            break;
    }
    return [NSString stringWithFormat:@"%@%@", baseURL, self.filename];
}

@end
