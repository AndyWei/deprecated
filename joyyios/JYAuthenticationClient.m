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
@property (nonatomic) UICKeyChainStore *keychain;
@end

@implementation JYAuthenticationClient

- (instancetype)init
{
    if (self = [super init])
    {
        self.keychain = [UICKeyChainStore keyChainStoreWithService:kKeyChainStoreAWS];
        
        _identityId = self.keychain[kAWSIdentityIdKey];
        _token = self.keychain[kAWSTokenKey];

        NSString *expiryTimeStr = self.keychain[kAWSTokenExpiryTimeKey];
        _tokenExpiryTime = expiryTimeStr ? [expiryTimeStr doubleValue] : 0.0f;
    }
    
    return self;
}

- (BOOL)isAuthenticated
{
    return [JYCredential currentCredential].tokenValidInSeconds > 0;
}

- (BOOL)_isTokenValid
{
    if (!self.identityId)
    {
        return NO;
    }

    if (!self.token)
    {
        return NO;
    }

    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    return (now < self.tokenExpiryTime);
}

- (void)setIdentityId:(NSString *)identityId
{
    _identityId = identityId;
    self.keychain[kAWSIdentityIdKey] = identityId;
}

- (void)setToken:(NSString *)token
{
    _token = token;
    self.keychain[kAWSTokenKey] = token;
}

- (void)setTokenExpiryTime:(NSTimeInterval)tokenExpiryTime
{
    _tokenExpiryTime = tokenExpiryTime;
    self.keychain[kAWSTokenExpiryTimeKey] = [NSString stringWithFormat:@"%.0f", tokenExpiryTime];
}

// call gettoken and set our values from returned result
- (AWSTask *)getToken
{
    if (![self isAuthenticated])
    {
        NSLog(@"Error: not authenticated by joyyserver, cannot get IdentityId and OpenID token");
        return [AWSTask taskWithError:[NSError errorWithDomain:kJYAuthenticationClientDomain
                                                         code:JYAuthenticationErrorLoginFailed
                                                     userInfo:nil]];
    }

    if ([self _isTokenValid])
    {
        JYAuthenticationResponse *authResponse = [JYAuthenticationResponse new];
        authResponse.token = self.token;
        authResponse.identityId = self.identityId;

        NSLog(@"Success: token is not expired, no need to get a new one");
        return [AWSTask taskWithResult:authResponse];
    }

    __weak typeof(self) weakSelf = self;
    return [[AWSTask taskWithResult:nil] continueWithBlock:^id(AWSTask *task) {

        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager managerWithToken];
        NSString *url = [NSString apiURLWithPath:@"cognito"];
        NSError *error = nil;
        NSDictionary *response = [manager syncGET:url parameters:nil operation:NULL error:&error];

        if (!response)
        {
            NSLog(@"Error: no response from AWS server");
            return [AWSTask taskWithError:[NSError errorWithDomain:kJYAuthenticationClientDomain
                                                             code:JYAuthenticationErrorNoCognitoResponse
                                                         userInfo:nil]];
        }
        
        NSString *identityId = [response objectForKey:@"IdentityId"];
        NSString *token = [response objectForKey:@"Token"];

        if (!identityId || !token)
        {
            NSLog(@"Error: invalid response from AWS server");
            return [AWSTask taskWithError:[NSError errorWithDomain:kJYAuthenticationClientDomain
                                                             code:JYAuthenticationErrorInvalidCognito
                                                         userInfo:nil]];
        }

        JYAuthenticationResponse *authResponse = [JYAuthenticationResponse new];

        weakSelf.identityId = authResponse.identityId = identityId;
        weakSelf.token = authResponse.token = token;
        NSUInteger tokenDuration = [response unsignedIntegerValueForKey:@"tokenDuration"];
        weakSelf.tokenExpiryTime = [NSDate timeIntervalSinceReferenceDate] + tokenDuration;

        NSLog(@"Success: got new token from joyyserver");
        return [AWSTask taskWithResult:authResponse];
    }];
}

@end
