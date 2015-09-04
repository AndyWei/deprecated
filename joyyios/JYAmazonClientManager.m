//
//  JYAmazonClientManager.m
//  joyyios
//
//  Created by Ping Yang on 9/1/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYAmazonClientManager.h"
#import "JYAuthenticatedIdentityProvider.h"
#import "JYAuthenticationClient.h"


@interface JYAmazonClientManager()
@property (nonatomic) AWSCognitoCredentialsProvider *credentialsProvider;
@property (atomic, copy) AWSContinuationBlock completionHandler;
@property (nonatomic) JYAuthenticationClient *authClient;
@end

@implementation JYAmazonClientManager

+ (JYAmazonClientManager *)sharedInstance
{
    static JYAmazonClientManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [JYAmazonClientManager new];
        sharedInstance.authClient = [JYAuthenticationClient new];
    });
    return sharedInstance;
}

- (void)goActiveWithCompletionHandler:(AWSContinuationBlock)completionHandler
{
    self.completionHandler = completionHandler;

    if ([JYCredential currentCredential].tokenValidInSeconds > 0)
    {
        [self _completeLogin:@{ kAuthProviderName: [JYCredential currentCredential].idString }];
    }
}

- (void)_completeLogin:(NSDictionary *)logins
{
    AWSTask *task;
    if (self.credentialsProvider == nil)
    {
        task = [self _initializeProviders:logins];
    }
    else
    {
        task = [self.credentialsProvider refresh];
    }

    if (!self.completionHandler)
    {
        self.completionHandler = ^id(AWSTask *task) {
            return nil;
        };
    }
    [task continueWithBlock:self.completionHandler];
}

- (AWSTask *)_initializeProviders:(NSDictionary *)logins
{
    NSLog(@"initializing providers...");
    [AWSLogger defaultLogger].logLevel = AWSLogLevelWarn;

    id<AWSCognitoIdentityProvider> identityProvider = [[JYAuthenticatedIdentityProvider alloc] initWithRegionType:kCognitoRegionType identityId:nil identityPoolId:kCognitoIdentityPoolId logins:logins providerName:kAuthProviderName authClient:self.authClient];

    self.credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:kCognitoRegionType identityProvider:identityProvider unauthRoleArn:nil authRoleArn:nil];

    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:kCognitoRegionType credentialsProvider:self.credentialsProvider];

    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;

    return [self.credentialsProvider refresh];
}

@end
