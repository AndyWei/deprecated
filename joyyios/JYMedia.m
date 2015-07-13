//
//  JYMedia.m
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYMedia.h"

@implementation JYMedia

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        if (dict)
        {
            self.mediaId = [[dict objectForKey:@"id"] unsignedIntegerValue];
            self.userId = [[dict objectForKey:@"user_id"] unsignedIntegerValue];
            self.pathVersion = [[dict objectForKey:@"path_version"] unsignedIntegerValue];

            self.filename = [dict objectForKey:@"filename"];
            self.caption = [dict objectForKey:@"caption"];

            self.isLocal = NO;
        }
    }
    return self;
}

- (NSString *)url
{
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
