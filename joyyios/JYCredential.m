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
        self.keychain = [UICKeyChainStore keyChainStoreWithService:kKeyChainStoreAWS];

        _phoneNumber = self.keychain[kAPIPhoneNumberKey];
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

- (void)setPhoneNumber:(NSString *)phoneNumber
{
    _phoneNumber = phoneNumber;
    self.keychain[kAPIPhoneNumberKey] = _phoneNumber;
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

    if ([dict valueForKey:@"phone"])
    {
        self.phoneNumber = [dict valueForKey:@"phone"];
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
    return (!self.phoneNumber || !self.password || !self.idString);
}

@end
