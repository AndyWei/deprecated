//
//  JYAuthenticatedIdentityProvider.m
//  joyyios
//
//  Created by Ping Yang on 9/1/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AWSCore/AWSCore.h>

#import "JYAuthenticatedIdentityProvider.h"
#import "JYAuthenticationClient.h"

@interface JYAuthenticatedIdentityProvider()
@property (strong, atomic) JYAuthenticationClient *client;
@property (strong, atomic) NSString *providerName;
@property (strong, atomic) NSString *token;
@end

@implementation JYAuthenticatedIdentityProvider
@synthesize providerName=_providerName;
@synthesize token=_token;

- (instancetype)initWithRegionType:(AWSRegionType)regionType identityId:(NSString *)identityId identityPoolId:(NSString *)identityPoolId logins:(NSDictionary *)logins providerName:(NSString *)providerName authClient:(JYAuthenticationClient *)client
{
    if (self = [super initWithRegionType:regionType identityId:identityId accountId:nil identityPoolId:identityPoolId logins:logins])
    {
        self.client = client;
        self.providerName = providerName;
    }
    return self;
}

// Get valid identityId and openIdToken from self.client
// If the identityId and openIdToken is expired (i.e., over 24 hours), client will get new ones from Joyyserver
- (AWSTask *)refresh
{
    return [[self.client getToken] continueWithSuccessBlock:^id(AWSTask *task) {
        if (task.result)
        {
            JYAuthenticationResponse *response = task.result;
            
            // potential for identity change here
            self.identityId = response.identityId;
            self.token = response.token;
        }
        return [AWSTask taskWithResult:self.identityId];
    }];
}

- (BOOL)isAuthenticated
{
    return [JYCredential current].idString != nil;
}

@end
