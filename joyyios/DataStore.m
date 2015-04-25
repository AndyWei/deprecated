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
    [[NSUserDefaults standardUserDefaults] setDouble:seconds forKey:kKeyAPITokenExpireTime];
}

- (NSTimeInterval)tokenExpireTime
{
    NSTimeInterval expireTime = 0.0f;
    if ([[NSUserDefaults standardUserDefaults] doubleForKey:kKeyAPITokenExpireTime])
    {
        expireTime = [[NSUserDefaults standardUserDefaults] doubleForKey:kKeyAPITokenExpireTime];
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

// DeviceToken
- (void)setDeviceToken:(NSString *)token
{
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:kKeyDeviceToken];
}

- (NSString *)deviceToken
{
    NSString *token = nil;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kKeyDeviceToken])
    {
        token = [[NSUserDefaults standardUserDefaults] objectForKey:kKeyDeviceToken];
    }
    return token;
}

// Badge Count
- (void)setBadgeCount:(NSInteger)count
{
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:kKeyBadgeCount];
}

- (NSInteger)badgeCount
{
    return[[NSUserDefaults standardUserDefaults] integerForKey:kKeyBadgeCount];
}

@end
