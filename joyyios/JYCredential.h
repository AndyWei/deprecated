//
//  JYCredential.h
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@interface JYCredential : NSObject

+ (JYCredential *)mine;

@property (nonatomic) NSString *email;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *password;
@property (nonatomic) NSString *token;
@property (nonatomic) NSString *idString;
@property (nonatomic, readonly) BOOL isEmpty;
@property (nonatomic, readonly) NSInteger tokenValidInSeconds;
@property (nonatomic, readonly) NSUInteger userId;

- (void)save:(NSDictionary *)dict;

@end
