//
//  JYAuthenticationClient.h
//  joyyios
//
//  Created by Ping Yang on 9/1/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

typedef NS_ENUM(NSUInteger, JYAuthenticationErrorType)
{
    JYAuthenticationErrorInvalidConfig,
    JYAuthenticationErrorLoginFailed,
    JYAuthenticationErrorNoCognitoResponse,
    JYAuthenticationErrorNoIdentityId,
    JYAuthenticationErrorNoToken
};

@class AWSTask;

@interface JYAuthenticationResponse : NSObject

@property (nonatomic, strong, readonly) NSString *identityId;
@property (nonatomic, strong, readonly) NSString *token;

@end

@interface JYAuthenticationClient : NSObject

- (instancetype)init;
- (BOOL)isAuthenticated;
- (AWSTask *)getToken;

@end
