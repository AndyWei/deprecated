//
//  User.h
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//


@interface User : NSObject

+ (User *)currentUser;

@property(nonatomic, strong) NSDictionary *credential;
@property(nonatomic, strong, readonly) NSString *email;
@property(nonatomic, strong, readonly) NSString *username;
@property(nonatomic, strong, readonly) NSString *password;
@property(nonatomic, strong, readonly) NSString *userId;
@property(nonatomic, strong, readonly) NSString *token;
@property(nonatomic, readonly) NSTimeInterval tokenExpireTimeInSecs;


- (BOOL)load;

@end
