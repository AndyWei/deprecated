//
//  JYCredential.h
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@interface JYCredential : NSObject

+ (JYCredential *)current;

@property (nonatomic) NSNumber *userId;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *password;
@property (nonatomic) NSString *phoneNumber;
@property (nonatomic) NSString *token;

@property (nonatomic) NSUInteger yrsValue;
@property (nonatomic, readonly) NSInteger tokenValidInSeconds;

- (void)save:(NSDictionary *)dict;
- (void)clear;
- (BOOL)isInvalid;

@end
