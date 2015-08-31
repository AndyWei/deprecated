//
//  JYUser.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYDataStore.h"
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
    _name = [_credential valueForKey:@"name"];
    _password = [_credential valueForKey:@"password"];
    _token = [_credential valueForKey:@"token"];
    _userIdString = [_credential valueForKey:@"id"];
    _userId = [_credential unsignedIntegerValueForKey:@"id"];
}

- (void)setCredential:(NSDictionary *)credential
{
    _credential = credential;
    [self _loadProperties];
    _tokenExpireTimeInSecs = [NSDate timeIntervalSinceReferenceDate] + k60Minutes;

    [JYDataStore sharedInstance].tokenExpireTime = _tokenExpireTimeInSecs;
    [JYDataStore sharedInstance].userCredential = _credential;
}

- (BOOL)exists
{
    if (_credential != nil)
    {
        return YES;
    }

    _credential = [JYDataStore sharedInstance].userCredential;

    if (_credential != nil)
    {
        [self _loadProperties];
        _tokenExpireTimeInSecs = [JYDataStore sharedInstance].tokenExpireTime;
        return YES;
    }

    return NO;
}

@end
