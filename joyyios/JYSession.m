//
//  JYSession.m
//  joyyios
//
//  Created by Ping Yang on 1/30/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "JYSession.h"

@interface JYSession ()
@end

@implementation JYSession

#pragma mark - MTLFMDBSerializing methods

+ (NSDictionary *)FMDBColumnsByPropertyKey
{
    return @{
             @"sessionId": @"id",
             @"userId": @"user_id",
             @"isGroup": @"is_group"
             };
}

+ (NSArray *)FMDBPrimaryKeys
{
    return @[@"id"];
}

+ (NSString *)FMDBTableName
{
    return @"session";
}

#pragma mark - Initialization

- (instancetype)initWithXMPPMessage:(XMPPMessage *)message isOutgoing:(BOOL)isOutgoing
{
    if (self = [super init])
    {
        self.userId = [JYCredential current].userId;
        self.isGroup = [NSNumber numberWithBool:NO];
        self.sessionId = isOutgoing? [message.to.bare uint64Number]:[message.from.bare uint64Number];
    }
    return self;
}

@end
