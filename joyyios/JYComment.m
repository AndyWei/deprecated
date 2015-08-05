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
@property(nonatomic) NSString* content;
@end

@implementation JYComment

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        if (dict)
        {
            _commentId = [[dict objectForKey:@"id"] unsignedIntegerValue];
            _postId = [[dict objectForKey:@"post"] unsignedIntegerValue];
            _ownerId = [[dict objectForKey:@"owner"] unsignedIntegerValue];
            _content = [dict objectForKey:@"content"];
        }
    }
    return self;
}

- (NSString *)contentString
{
    return _content;
}

@end
