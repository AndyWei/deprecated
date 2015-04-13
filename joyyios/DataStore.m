//
//  DataStore.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "DataStore.h"

@implementation DataStore

+ (instancetype)sharedInstance
{
    static DataStore *_sharedInstance = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedInstance = [DataStore new];
    });

    return _sharedInstance;
}

// UserCredential
- (void)setUserCredential:(NSDictionary *)credential
{
    [[NSUserDefaults standardUserDefaults] setObject:credential forKey:kKeyUserCredential];
}

- (NSDictionary *)userCredential
{
    NSDictionary *credential = nil;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kKeyUserCredential])
    {
        credential = [[NSUserDefaults standardUserDefaults] objectForKey:kKeyUserCredential];
    }
    return credential;
}

// TokenExpireTime
- (void)setTokenExpireTime:(NSTimeInterval)seconds
{
    [[NSUserDefaults standardUserDefaults] setDouble:seconds forKey:kKeyTokenExpireTime];
}

- (NSTimeInterval)tokenExpireTime
{
    NSTimeInterval expireTime = 0.0f;
    if ([[NSUserDefaults standardUserDefaults] doubleForKey:kKeyTokenExpireTime])
    {
        expireTime = [[NSUserDefaults standardUserDefaults] doubleForKey:kKeyTokenExpireTime];
    }
    return expireTime;
}

// CurrentOrder
- (void)setCurrentOrder:(JYOrder *)order
{
    [[NSUserDefaults standardUserDefaults] setObject:order forKey:kKeyCurrentOrder];
}

- (JYOrder *)currentOrder
{
    JYOrder *order = nil;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kKeyCurrentOrder])
    {
        order = [[NSUserDefaults standardUserDefaults] objectForKey:kKeyCurrentOrder];
    }
    return order;
}

@end
