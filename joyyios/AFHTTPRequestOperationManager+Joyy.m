//
//  AFHTTPRequestOperationManager+Joyy.m
//  joyyios
//
//  Created by Ping Yang on 9/3/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@implementation AFHTTPRequestOperationManager (Joyy)

+ (AFHTTPRequestOperationManager *)managerWithPassword
{
    NSString *username = [JYCredential mine].username;
    NSString *password = [JYCredential mine].password;

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:username password:password];

    return manager;
}

+ (AFHTTPRequestOperationManager *)managerWithToken
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYCredential mine].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    return manager;
}

@end
