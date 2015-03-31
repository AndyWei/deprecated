//
//  User.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "DataStore.h"
#import "User.h"


@implementation User

+ (User *)currentUser
{
    static User *_currentUser;
    static dispatch_once_t done;
    dispatch_once(&done, ^{
        _currentUser = [User new];
    });
    return _currentUser;
}

- (void)setCredential:(NSDictionary *)credential
{
    _credential = credential;
    _email = [_credential valueForKey:@"email"];
    _username = [_credential valueForKey:@"username"];
    _password = [_credential valueForKey:@"password"];
    _token = [_credential valueForKey:@"token"];
    _userId = [_credential valueForKey:@"id"];
    _tokenExpireTimeInSecs = [NSDate timeIntervalSinceReferenceDate] + 30 * 60;

    [[DataStore sharedInstance] saveTokenExpireTime:_tokenExpireTimeInSecs];
    [[DataStore sharedInstance] saveUserCredential:_credential];
}

- (BOOL)load
{
    if (_credential != nil)
    {
        return YES;
    }

    _credential = [[DataStore sharedInstance] loadUserCredential];

    if (_credential != nil) {
        _email = [_credential valueForKey:@"email"];
        _username = [_credential valueForKey:@"username"];
        _password = [_credential valueForKey:@"password"];
        _token = [_credential valueForKey:@"token"];
        _userId = [_credential valueForKey:@"id"];
        _tokenExpireTimeInSecs = [[DataStore sharedInstance] loadTokenExpireTime];
        return YES;
    }

    return NO;
}

@end
