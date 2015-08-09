//
//  JYComment.m
//  joyyios
//
//  Created by Ping Yang on 5/24/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYComment.h"
#import "JYUser.h"

@interface JYComment ()
@end

@implementation JYComment

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        if (dict)
        {
            _content   = [dict objectForKey:@"content"];
            _commentId = [dict unsignedIntegerValueForKey:@"id"];
            _postId    = [dict unsignedIntegerValueForKey:@"post"];
            _ownerId   = [dict unsignedIntegerValueForKey:@"owner"];
            _timestamp = [dict unsignedIntegerValueForKey:@"ct"];
        }
    }
    return self;
}

@end
