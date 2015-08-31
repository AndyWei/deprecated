//
//  JYCredential.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYDataStore.h"

@implementation JYCredential

+ (JYCredential *)current
{
    static JYCredential *_current;
    static dispatch_once_t done;
    dispatch_once(&done, ^{
        _current = [JYCredential new];
    });
    return _current;
}

- (void)_loadProperties
{
    _email = [_dictionary valueForKey:@"email"];
    _name = [_dictionary valueForKey:@"name"];
    _password = [_dictionary valueForKey:@"password"];
    _token = [_dictionary valueForKey:@"token"];
    _idString = [_dictionary valueForKey:@"id"];
    _personId = [_dictionary unsignedIntegerValueForKey:@"id"];
}

- (void)setDictionary:(NSDictionary *)dictionary
{
    _dictionary = dictionary;
    [self _loadProperties];
    _tokenExpireTimeInSecs = [NSDate timeIntervalSinceReferenceDate] + k60Minutes;

    [JYDataStore sharedInstance].tokenExpireTime = _tokenExpireTimeInSecs;
    [JYDataStore sharedInstance].userCredential = _dictionary;
}

- (BOOL)exists
{
    if (_dictionary != nil)
    {
        return YES;
    }

    _dictionary = [JYDataStore sharedInstance].userCredential;

    if (_dictionary != nil)
    {
        [self _loadProperties];
        _tokenExpireTimeInSecs = [JYDataStore sharedInstance].tokenExpireTime;
        return YES;
    }

    return NO;
}

@end
