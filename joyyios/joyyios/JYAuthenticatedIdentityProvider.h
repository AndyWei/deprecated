//
//  JYAuthenticatedIdentityProvider.h
//  joyyios
//
//  Created by Ping Yang on 9/1/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "AWSIdentityProvider.h"

@class JYAuthenticationClient;

@interface JYAuthenticatedIdentityProvider : AWSAbstractCognitoIdentityProvider

- (instancetype)initWithRegionType:(AWSRegionType)regionType identityId:(NSString *)identityId identityPoolId:(NSString *)identityPoolId logins:(NSDictionary *)logins providerName:(NSString *)providerName authClient:(JYAuthenticationClient *)client;

- (BOOL)isAuthenticated;

@end
