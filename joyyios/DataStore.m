//
//  DataStore.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "DataStore.h"

@implementation DataStore

+ (DataStore *)sharedInstance
{
    static DataStore *_sharedInstance;
    static dispatch_once_t done;
    dispatch_once(&done, ^{
      _sharedInstance = [DataStore new];
    });
    return _sharedInstance;
}

// UserCredential
- (void)saveUserCredential:(NSDictionary *)credential
{
    [[NSUserDefaults standardUserDefaults] setObject:credential forKey:kKeyUserCredential];
}

- (NSDictionary *)loadUserCredential
{
    NSDictionary *credential = nil;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kKeyUserCredential])
    {
        credential = [[NSUserDefaults standardUserDefaults] objectForKey:kKeyUserCredential];
    }
    return credential;
}

// TokenExpireTime
- (void)saveTokenExpireTime:(NSTimeInterval)seconds
{
    [[NSUserDefaults standardUserDefaults] setDouble:seconds forKey:kKeyTokenExpireTime];
}

- (NSTimeInterval)loadTokenExpireTime
{
    NSTimeInterval expireTime = 0.0f;
    if ([[NSUserDefaults standardUserDefaults] doubleForKey:kKeyTokenExpireTime])
    {
        expireTime = [[NSUserDefaults standardUserDefaults] doubleForKey:kKeyUserCredential];
    }
    return expireTime;
}

@end
