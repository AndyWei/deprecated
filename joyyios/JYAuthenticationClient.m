//
//  JYAuthenticationClient.m
//  joyyios
//
//  Created by Ping Yang on 9/1/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AWSCore/AWSCore.h>
#import <UICKeychainStore/UICKeychainStore.h>

#import "JYAuthenticationClient.h"
#import "NSURLSession+SynchronousTask.h"

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
@property (nonatomic) uint64_t tokenExpiryTime;
@property (nonatomic) UICKeyChainStore *keychain;
@end

// KeyChain -- DO NOT MODIFY!!!
//static NSString *const kKeyChainStoreAWS = @"com.joyyapp.aws";
static NSString *const kKeyChainStoreAWS = @"com.winkrock.aws";
static NSString *const kAWSIdentityIdKeyPrefix = @"aws_identity_id";
static NSString *const kAWSTokenKeyPrefix      = @"aws_openid_token";
static NSString *const kAWSTokenExpiryTimeKeyPrefix = @"aws_openid_token_expiry_time";

@implementation JYAuthenticationClient
@synthesize identityId = _identityId;
@synthesize token = _token;
@synthesize tokenExpiryTime = _tokenExpiryTime;

- (instancetype)init
{
    if (self = [super init])
    {
        self.keychain = [UICKeyChainStore keyChainStoreWithService:kKeyChainStoreAWS];
    }
    
    return self;
}

- (BOOL)isAuthenticated
{
    return [JYCredential current].tokenValidInSeconds > 0;
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

    NSUInteger now = (NSUInteger)[NSDate timeIntervalSinceReferenceDate];
    return (now < self.tokenExpiryTime);
}

- (NSString *)identityIdKey
{
    NSString *userid = [JYCredential current].idString;
    return [NSString stringWithFormat:@"%@_%@", kAWSIdentityIdKeyPrefix, userid];
}

- (void)setIdentityId:(NSString *)identityId
{
    _identityId = identityId;
    self.keychain[self.identityIdKey] = identityId;
}

- (NSString *)identityId
{
    if (!_identityId)
    {
        _identityId = self.keychain[self.identityIdKey];
    }
    return _identityId;
}

- (NSString *)tokenKey
{
    NSString *userid = [JYCredential current].idString;
    return [NSString stringWithFormat:@"%@_%@", kAWSTokenKeyPrefix, userid];
}

- (void)setToken:(NSString *)token
{
    _token = token;
    self.keychain[self.tokenKey] = token;
}

- (NSString *)token
{
    if (!_token)
    {
        _token = self.keychain[self.tokenKey];
    }
    return _token;
}

- (NSString *)tokenExpiryTimeKey
{
    NSString *userid = [JYCredential current].idString;
    return [NSString stringWithFormat:@"%@_%@", kAWSTokenExpiryTimeKeyPrefix, userid];
}

- (void)setTokenExpiryTime:(uint64_t)tokenExpiryTime
{
    _tokenExpiryTime = tokenExpiryTime;
    self.keychain[self.tokenExpiryTimeKey] = [NSString stringWithFormat:@"%tu", tokenExpiryTime];
}

- (uint64_t)tokenExpiryTime
{
    if (_tokenExpiryTime == 0)
    {
        NSString *expiryTimeStr = self.keychain[self.tokenExpiryTimeKey];
        _tokenExpiryTime = expiryTimeStr ? [expiryTimeStr uint64Value] : 0;
    }
    return _tokenExpiryTime;
}

- (AWSTask *)_getTokenFromWinkRock
{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setHTTPAdditionalHeaders:@{@"Authorization": [NSString stringWithFormat:@"Bearer %@",[JYCredential current].token]}];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    NSURL *url = [NSURL URLWithString:[NSString apiURLWithPath:@"auth/cognito"]];
    NSError *error = nil;
    NSURLResponse *response = nil;
    NSData *data = [session sendSynchronousDataTaskWithURL:url returningResponse:&response error:&error];

    if (error || !data)
    {
        NSLog(@"Error: no cognito response from winkrock server");
        return [AWSTask taskWithError:[NSError errorWithDomain:kJYAuthenticationClientDomain
                                                          code:JYAuthenticationErrorNoCognitoResponse
                                                      userInfo:nil]];
    }

    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:kNilOptions
                                                           error:&error];

    if (error)
    {
        NSLog(@"Error: the response from winkrock server is not json");
        return [AWSTask taskWithError:[NSError errorWithDomain:kJYAuthenticationClientDomain
                                                          code:JYAuthenticationErrorNoCognitoResponse
                                                      userInfo:nil]];
    }

    NSString *identityId = [json objectForKey:@"IdentityId"];
    NSString *token = [json objectForKey:@"Token"];

    if (!identityId)
    {
        NSLog(@"Error: no IdentityId");
        return [AWSTask taskWithError:[NSError errorWithDomain:kJYAuthenticationClientDomain
                                                          code:JYAuthenticationErrorNoIdentityId
                                                      userInfo:nil]];
    }

    if (!token)
    {
        NSLog(@"Error: No Token");
        return [AWSTask taskWithError:[NSError errorWithDomain:kJYAuthenticationClientDomain
                                                          code:JYAuthenticationErrorNoToken
                                                      userInfo:nil]];
    }

    JYAuthenticationResponse *authResponse = [JYAuthenticationResponse new];

    self.identityId = authResponse.identityId = identityId;
    self.token = authResponse.token = token;
    NSUInteger now = (NSUInteger)[NSDate timeIntervalSinceReferenceDate];
    self.tokenExpiryTime = now + 86400;

    NSLog(@"Success: got new token from winkrock server");

    return [AWSTask taskWithResult:authResponse];
}

// call getToken and set our values from returned result
- (AWSTask *)getToken
{
    if (![self isAuthenticated])
    {
        NSLog(@"Error: not authenticated by winkrock server, cannot get IdentityId and OpenID token");
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

    return [self _getTokenFromWinkRock];

}

@end
