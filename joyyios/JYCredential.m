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
@property (nonatomic) uint64_t tokenExpiryTime;
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
        _token    = self.keychain[kAPITokenKey];

        NSString *expiryTimeStr = self.keychain[kAPITokenExpiryTimeKey];
        _tokenExpiryTime = expiryTimeStr ? [expiryTimeStr integerValue] : 0;

        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;

        NSString *userIdStr = self.keychain[kAPIUserIdKey];
        _userId = userIdStr? [f numberFromString:userIdStr]: 0;

        NSString *yrsStr = self.keychain[kAPIYrsKey];
        _yrsValue = yrsStr ? [yrsStr uint64Value]: 0;
    }

    return self;
}

- (void)setYrsValue:(uint64_t)yrsValue
{
    _yrsValue = yrsValue;
    self.keychain[kAPIYrsKey] = [NSString stringWithFormat:@"%llu", yrsValue];
}

- (void)setUserId:(NSNumber *)userId
{
    _userId = userId;
    self.keychain[kAPIUserIdKey] = [NSString stringWithFormat:@"%llu", [userId unsignedLongLongValue]];
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

- (void)setTokenExpiryTime:(uint64_t)tokenExpiryTime
{
    _tokenExpiryTime = tokenExpiryTime;
    if (tokenExpiryTime == 0)
    {
        self.keychain[kAPITokenExpiryTimeKey] = nil;
    }
    else
    {
        self.keychain[kAPITokenExpiryTimeKey] = [NSString stringWithFormat:@"%llu", tokenExpiryTime];
    }
}

- (NSInteger)tokenValidInSeconds
{
    uint64_t now = (uint64_t)[NSDate timeIntervalSinceReferenceDate];
    int64_t secsLeft = (self.tokenExpiryTime > now) ? (self.tokenExpiryTime - now): (-1)*(now - self.tokenExpiryTime);
    return (NSInteger)secsLeft;
}

- (void)save:(NSDictionary *)dict
{
    if ([dict objectForKey:@"userid"])
    {
        self.userId = [dict objectForKey:@"userid"];
    }

    if ([dict objectForKey:@"username"])
    {
        self.username = [dict objectForKey:@"username"];
    }

    if ([dict objectForKey:@"yrs"])
    {
        self.yrsValue = [[dict objectForKey:@"yrs"] unsignedLongLongValue];
    }

    if ([dict objectForKey:@"token"])
    {
        self.token = [dict objectForKey:@"token"];

        uint64_t tokenDuration = [[dict objectForKey:@"token_ttl"] unsignedLongLongValue];
        uint64_t now = (uint64_t)[NSDate timeIntervalSinceReferenceDate];
        self.tokenExpiryTime = now + tokenDuration;
    }
}

- (BOOL)isInvalid
{
    BOOL invalid = (!self.username || !self.password || !self.userId);
    return invalid;
}

- (void)clear
{
    self.username = nil;
    self.password = nil;
    self.phoneNumber = nil;
    self.token = nil;
    self.userId = 0;
    self.yrsValue = 0;
    self.tokenExpiryTime = 0;
}

@end
