//
//  JYAuthenticationClient.m
//  joyyios
//
//  Created by Ping Yang on 9/1/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AWSCore/AWSCore.h>
#import <UICKeychainStore/UICKeychainStore.h>

#import "AFHTTPRequestOperationManager+Synchronous.h"
#import "JYAuthenticationClient.h"

NSString *const kJYAuthenticationClientDomain = @"JYAuthenticationClient";
NSString *const kIdentityIdKey = @"identityId";
NSString *const kTokenKey = @"openIDToken";
NSString *const kTokenExpiryTimeKey = @"tokenExpiryTime";

@interface JYAuthenticationResponse()

@property (nonatomic, strong) NSString *identityId;
@property (nonatomic, strong) NSString *token;

@end

@implementation JYAuthenticationResponse
@end

@interface JYAuthenticationClient()
@property (nonatomic) NSString *identityId;
@property (nonatomic) NSString *token;
@property (nonatomic) NSTimeInterval tokenExpiryTime;

// used to save state of authentication
@property (nonatomic, strong) UICKeyChainStore *keychain;

@end

@implementation JYAuthenticationClient

- (instancetype)init
{
    if (self = [super init])
    {
        self.keychain = _keychain = [UICKeyChainStore keyChainStoreWithService:[NSString stringWithFormat:@"%@.%@", [NSBundle mainBundle].bundleIdentifier, [JYAuthenticationClient class]]];
        
        _identityId = self.keychain[kIdentityIdKey];
        _token = self.keychain[kTokenKey];

        NSString *expiryTimeStr = self.keychain[kTokenExpiryTimeKey];
        _tokenExpiryTime = expiryTimeStr ? [expiryTimeStr doubleValue] : 0.0f;
    }
    
    return self;
}

- (BOOL)isAuthenticated
{
    return [JYCredential current].idString != nil;
}

- (BOOL)_isTokenExpired
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    return self.tokenExpiryTime < now;
}

- (void)setIdentityId:(NSString *)identityId
{
    _identityId = identityId;
    self.keychain[kIdentityIdKey] = identityId;
}

- (void)setToken:(NSString *)token
{
    _token = token;
    self.keychain[kTokenKey] = token;
}

- (void)setTokenExpiryTime:(NSTimeInterval)tokenExpiryTime
{
    _tokenExpiryTime = tokenExpiryTime;
    self.keychain[kTokenExpiryTimeKey] = [NSString stringWithFormat:@"%.0f", tokenExpiryTime];
}

// call gettoken and set our values from returned result
- (AWSTask *)getToken
{
    if (![self isAuthenticated])
    {
        return [AWSTask taskWithError:[NSError errorWithDomain:kJYAuthenticationClientDomain
                                                         code:JYAuthenticationErrorLoginFailed
                                                     userInfo:nil]];
    }

    if (![self _isTokenExpired])
    {
        JYAuthenticationResponse *authResponse = [JYAuthenticationResponse new];
        authResponse.token = self.token;
        authResponse.identityId = self.identityId;
            
        return [AWSTask taskWithResult:authResponse];
    }

    __weak typeof(self) weakSelf = self;
    return [[AWSTask taskWithResult:nil] continueWithBlock:^id(AWSTask *task) {

        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSString *apiToken = [NSString stringWithFormat:@"Bearer %@", [JYCredential current].token];
        [manager.requestSerializer setValue:apiToken forHTTPHeaderField:@"Authorization"];

        NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"cognito"];
        NSError *error = nil;
        NSDictionary *response = [manager syncGET:url parameters:nil operation:NULL error:&error];

        if (!response)
        {
            return [AWSTask taskWithError:[NSError errorWithDomain:kJYAuthenticationClientDomain
                                                             code:JYAuthenticationErrorNoCognitoResponse
                                                         userInfo:nil]];
        }
        
        NSString *identityId = [response objectForKey:@"IdentityId"];
        NSString *token = [response objectForKey:@"Token"];

        if (!identityId || !token)
        {
            return [AWSTask taskWithError:[NSError errorWithDomain:kJYAuthenticationClientDomain
                                                             code:JYAuthenticationErrorInvalidCognito
                                                         userInfo:nil]];
        }

        JYAuthenticationResponse *authResponse = [JYAuthenticationResponse new];

        weakSelf.identityId = authResponse.identityId = identityId;
        weakSelf.token = authResponse.token = token;
        NSUInteger tokenDuration = [response unsignedIntegerValueForKey:@"tokenDuration"];
        weakSelf.tokenExpiryTime = [NSDate timeIntervalSinceReferenceDate] + tokenDuration;

        return [AWSTask taskWithResult:authResponse];
    }];
}

@end
