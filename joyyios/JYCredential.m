//
//  JYCredential.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <UICKeychainStore/UICKeychainStore.h>
#import "JYDataStore.h"

@interface JYCredential()
@property (nonatomic) UICKeyChainStore *keychain;
@property (nonatomic) NSTimeInterval tokenExpiryTime;
@end

@implementation JYCredential

+ (JYCredential *)currentCredential
{
    static JYCredential *_current;
    static dispatch_once_t done;
    dispatch_once(&done, ^{
        _current = [JYCredential new];
    });
    return _current;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.keychain = [UICKeyChainStore keyChainStoreWithService:kKeyChainStoreAWS];

        _email    = self.keychain[kAPIEmailKey];
        _password = self.keychain[kAPIPasswordKey];
        _username = self.keychain[kAPIUsernameKey];
        _idString = self.keychain[kAPIUserIdKey];
        _token    = self.keychain[kAPITokenKey];

        NSString *expiryTimeStr = self.keychain[kAWSTokenExpiryTimeKey];
        _tokenExpiryTime = expiryTimeStr ? [expiryTimeStr doubleValue] : 0.0f;

        _userId = _idString? [_idString unsignedIntegerValue] : 0;
    }

    return self;
}

- (void)setEmail:(NSString *)email
{
    _email = email;
    self.keychain[kAPIEmailKey] = email;
}

- (void)setPassword:(NSString *)password
{
    _password = password;
    self.keychain[kAPIPasswordKey] = password;
}

- (void)setUsername:(NSString *)username
{
    _username = username;
    self.keychain[kAPIUsernameKey] = username;
}

- (void)setIdString:(NSString *)idString
{
    _idString = idString;
    self.keychain[kAPIUserIdKey] = idString;
    _userId = _idString? [_idString unsignedIntegerValue] : 0;
}

- (void)setToken:(NSString *)token
{
    _token = token;
    self.keychain[kAPITokenKey] = token;
}

- (void)setTokenExpiryTime:(NSTimeInterval)tokenExpiryTime
{
    _tokenExpiryTime = tokenExpiryTime;
    self.keychain[kAWSTokenExpiryTimeKey] = [NSString stringWithFormat:@"%.0f", tokenExpiryTime];
}

- (NSTimeInterval)tokenValidInSeconds
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    return self.tokenExpiryTime - now;
}

- (void)save:(NSDictionary *)dict
{
    if ([dict valueForKey:@"id"])
    {
        self.idString = [dict valueForKey:@"id"];
    }

    if ([dict valueForKey:@"email"])
    {
        self.email = [dict valueForKey:@"email"];
    }

    if ([dict valueForKey:@"username"])
    {
        self.username = [dict valueForKey:@"username"];
    }

    if ([dict valueForKey:@"token"])
    {
        self.token = [dict valueForKey:@"token"];

        NSUInteger tokenDuration = [dict unsignedIntegerValueForKey:@"tokenDuration"];
        self.tokenExpiryTime = [NSDate timeIntervalSinceReferenceDate] + tokenDuration;
    }
}

- (BOOL)isEmpty
{
    return (!self.email || !self.password || !self.idString);
}

@end
