//
//  AFHTTPRequestOperationManager+Joyy.m
//  joyyios
//
//  Created by Ping Yang on 9/3/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@implementation AFHTTPRequestOperationManager (Joyy)

+ (AFHTTPRequestOperationManager *)managerWithToken
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYCredential current].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    return manager;
}

@end
