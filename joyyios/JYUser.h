//
//  JYUser.h
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@interface JYUser : NSObject

+ (JYUser *)currentUser;

@property(nonatomic) NSDictionary *credential;
@property(nonatomic, readonly) NSString *email;
@property(nonatomic, readonly) NSString *username;
@property(nonatomic, readonly) NSString *password;
@property(nonatomic, readonly) NSString *token;
@property(nonatomic, readonly) NSTimeInterval tokenExpireTimeInSecs;
@property(nonatomic, readonly) NSUInteger userId;

- (BOOL)exists;

@end
