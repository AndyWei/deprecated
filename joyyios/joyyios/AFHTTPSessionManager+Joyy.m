//
//  AFHTTPSessionManager+Joyy.m
//  joyyios
//
//  Created by Ping Yang on 9/3/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@implementation AFHTTPSessionManager (Joyy)

+ (AFHTTPSessionManager *)managerWithToken
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYCredential current].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    return manager;
}

@end
