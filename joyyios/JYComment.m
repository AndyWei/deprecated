//
//  JYComment.m
//  joyyios
//
//  Created by Ping Yang on 5/24/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYComment.h"

@implementation JYComment

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        if (dict)
        {
            self.commentId = [[dict objectForKey:@"id"] unsignedIntegerValue];
            self.orderId = [[dict objectForKey:@"order_id"] unsignedIntegerValue];
            self.userId = [[dict objectForKey:@"user_id"] unsignedIntegerValue];
            self.body = [dict objectForKey:@"body"];
            self.username = [dict objectForKey:@"username"];
        }
    }
    return self;
}

- (NSString *)contentString
{
    return [NSString stringWithFormat:@"%@: %@", self.username, self.body];
}

@end
