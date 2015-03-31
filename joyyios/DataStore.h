//
//  DataStore.h
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//


@interface DataStore : NSObject

+ (DataStore *)sharedInstance;

- (void)saveUserCredential:(NSDictionary *)credential;
- (NSDictionary *)loadUserCredential;

- (void)saveTokenExpireTime:(NSTimeInterval)seconds;
- (NSTimeInterval)loadTokenExpireTime;

@end
