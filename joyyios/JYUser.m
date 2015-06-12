//
//  JYUser.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "DataStore.h"
#import "JYUser.h"

@implementation JYUser

+ (JYUser *)currentUser
{
    static JYUser *_currentUser;
    static dispatch_once_t done;
    dispatch_once(&done, ^{
        _currentUser = [JYUser new];
    });
    return _currentUser;
}

- (void)_loadProperties
{
    _email = [_credential valueForKey:@"email"];
    _username = [_credential valueForKey:@"username"];
    _password = [_credential valueForKey:@"password"];
    _token = [_credential valueForKey:@"token"];
    _userId = [[_credential valueForKey:@"id"] unsignedIntegerValue];
    _joyyorStatus = [[_credential valueForKey:@"joyyor_status"] unsignedIntegerValue];
}

- (void)setCredential:(NSDictionary *)credential
{
    _credential = credential;
    [self _loadProperties];
    _tokenExpireTimeInSecs = [NSDate timeIntervalSinceReferenceDate] + kTokenValidInSecs;

    [DataStore sharedInstance].tokenExpireTime = _tokenExpireTimeInSecs;
    [DataStore sharedInstance].userCredential = _credential;
}

- (BOOL)exists
{
    if (_credential != nil)
    {
        return YES;
    }

    _credential = [DataStore sharedInstance].userCredential;

    if (_credential != nil)
    {
        [self _loadProperties];
        _tokenExpireTimeInSecs = [DataStore sharedInstance].tokenExpireTime;
        return YES;
    }

    return NO;
}

@end
