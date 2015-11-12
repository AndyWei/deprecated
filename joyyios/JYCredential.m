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
static NSString *const kKeyChainStoreAPI = @"com.winkrock.api";
static NSString *const kAPIPasswordKey = @"api_password";
static NSString *const kAPIUserIdKey   = @"api_user_id";
static NSString *const kAPIUsernameKey = @"api_username";
static NSString *const kAPIPhoneNumberKey = @"api_phone_number";
static NSString *const kAPITokenKey    = @"api_token";
static NSString *const kAPITokenExpiryTimeKey = @"api_token_expiry_time";
static NSString *const kAPIYrsKey = @"api_yrs";

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

- (instancetype)init
{
    if (self = [super init])
    {
        self.keychain = [UICKeyChainStore keyChainStoreWithService:kKeyChainStoreAPI];

        _username = self.keychain[kAPIUsernameKey];
        _password = self.keychain[kAPIPasswordKey];
        _phoneNumber = self.keychain[kAPIPhoneNumberKey];
        _idString = self.keychain[kAPIUserIdKey];
        _token    = self.keychain[kAPITokenKey];

        _userId = _idString? [_idString unsignedIntegerValue] : 0;

        NSString *expiryTimeStr = self.keychain[kAPITokenExpiryTimeKey];
        _tokenExpiryTime = expiryTimeStr ? [expiryTimeStr unsignedIntegerValue] : 0;

        NSString *yrsStr = self.keychain[kAPIYrsKey];
        _yrs = yrsStr ? [yrsStr unsignedIntegerValue] : 0;
    }

    return self;
}

- (void)setUserId:(NSUInteger)userId
{
    _userId = userId;
    if (userId == 0)
    {
        self.idString = nil;
    }
    else
    {
        self.idString = [NSString stringWithFormat:@"%tu", _userId];
    }
}

- (void)setIdString:(NSString *)idString
{
    _idString = idString;
    self.keychain[kAPIUserIdKey] = _idString;
}

- (void)setUsername:(NSString *)username
{
    _username = username;
    self.keychain[kAPIUsernameKey] = _username;
}

- (void)setPassword:(NSString *)password
{
    _password = password;
    self.keychain[kAPIPasswordKey] = _password;
}

- (void)setPhoneNumber:(NSString *)phoneNumber
{
    _phoneNumber = phoneNumber;
    self.keychain[kAPIPhoneNumberKey] = _phoneNumber;
}

- (void)setToken:(NSString *)token
{
    _token = token;
    self.keychain[kAPITokenKey] = _token;
}

- (void)setTokenExpiryTime:(NSUInteger)tokenExpiryTime
{
    _tokenExpiryTime = tokenExpiryTime;
    if (tokenExpiryTime == 0)
    {
        self.keychain[kAPITokenExpiryTimeKey] = nil;
    }
    else
    {
        self.keychain[kAPITokenExpiryTimeKey] = [NSString stringWithFormat:@"%tu", tokenExpiryTime];
    }
}

- (void)setYrs:(NSUInteger)yrs
{
    _yrs = yrs;
    if (yrs == 0)
    {
        self.keychain[kAPIYrsKey] = nil;
    }
    else
    {
        self.keychain[kAPIYrsKey] = [NSString stringWithFormat:@"%tu", yrs];
    }
}

- (NSInteger)tokenValidInSeconds
{
    NSInteger now = (NSInteger)[NSDate timeIntervalSinceReferenceDate];
    return self.tokenExpiryTime - now;
}

- (void)save:(NSDictionary *)dict
{
    if ([dict objectForKey:@"id"])
    {
        self.userId = [[dict objectForKey:@"id"] unsignedIntegerValue];
    }

    if ([dict objectForKey:@"username"])
    {
        self.username = [dict objectForKey:@"username"];
    }

    if ([dict objectForKey:@"token"])
    {
        self.token = [dict objectForKey:@"token"];

        NSUInteger tokenDuration = [[dict objectForKey:@"token_ttl"] intValue];
        NSInteger now = (NSInteger)[NSDate timeIntervalSinceReferenceDate];
        self.tokenExpiryTime = now + tokenDuration;
    }
}

- (BOOL)isInvalid
{
    BOOL invalid = ((self.username == nil) || (self.password == nil) || (self.idString == nil));
    return invalid;
}

- (void)clear
{
    self.username = nil;
    self.password = nil;
    self.phoneNumber = nil;
    self.token = nil;
    self.userId = 0;
    self.tokenExpiryTime = 0;
}

@end
