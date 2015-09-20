//
//  JYCredential.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <UICKeychainStore/UICKeychainStore.h>

@interface JYCredential()
@property (nonatomic) UICKeyChainStore *keychain;
@property (nonatomic) NSUInteger tokenExpiryTime;
@end

// KeyChain -- DO NOT MODIFY!!!
static NSString *const kKeyChainStoreAPI = @"com.joyyapp.api";
static NSString *const kAPIPasswordKey = @"api_password";
static NSString *const kAPIUserIdKey   = @"api_user_id";
static NSString *const kAPIUsernameKey = @"api_username";
static NSString *const kAPITokenKey    = @"api_token";
static NSString *const kAPITokenExpiryTimeKey = @"api_token_expiry_time";

@implementation JYCredential

+ (JYCredential *)mine
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
        self.keychain = [UICKeyChainStore keyChainStoreWithService:kKeyChainStoreAPI];

        _password = self.keychain[kAPIPasswordKey];
        _username = self.keychain[kAPIUsernameKey];
        _idString = self.keychain[kAPIUserIdKey];
        _token    = self.keychain[kAPITokenKey];

        NSString *expiryTimeStr = self.keychain[kAPITokenExpiryTimeKey];
        _tokenExpiryTime = expiryTimeStr ? [expiryTimeStr unsignedIntegerValue] : 0;

        _userId = _idString? [_idString unsignedIntegerValue] : 0;
    }

    return self;
}

- (void)setPassword:(NSString *)password
{
    _password = password;
    self.keychain[kAPIPasswordKey] = _password;
}

- (void)setUsername:(NSString *)username
{
    _username = username;
    self.keychain[kAPIUsernameKey] = _username;
}

- (void)setIdString:(NSString *)idString
{
    _idString = idString;
    self.keychain[kAPIUserIdKey] = _idString;
    _userId = _idString? [_idString unsignedIntegerValue] : 0;
}

- (void)setToken:(NSString *)token
{
    _token = token;
    self.keychain[kAPITokenKey] = _token;
}

- (void)setTokenExpiryTime:(NSUInteger)tokenExpiryTime
{
    _tokenExpiryTime = tokenExpiryTime;
    self.keychain[kAPITokenExpiryTimeKey] = [NSString stringWithFormat:@"%tu", tokenExpiryTime];
}

- (NSInteger)tokenValidInSeconds
{
    NSInteger now = (NSInteger)[NSDate timeIntervalSinceReferenceDate];
    return self.tokenExpiryTime - now;
}

- (void)save:(NSDictionary *)dict
{
    if ([dict valueForKey:@"id"])
    {
        self.idString = [dict valueForKey:@"id"];
    }

    if ([dict valueForKey:@"username"])
    {
        self.username = [dict valueForKey:@"username"];
    }

    if ([dict valueForKey:@"token"])
    {
        self.token = [dict valueForKey:@"token"];

        NSUInteger tokenDuration = [dict unsignedIntegerValueForKey:@"tokenDuration"];
        NSInteger now = (NSInteger)[NSDate timeIntervalSinceReferenceDate];
        self.tokenExpiryTime = now + tokenDuration;
    }
}

- (BOOL)isEmpty
{
//    return (!self.username || !self.password || !self.idString);
    return YES;
}

@end
