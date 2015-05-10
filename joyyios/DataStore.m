//
//  DataStore.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "DataStore.h"


NSString *const kKeyAPITokenExpireTime = @"APITokenExpireTime";
NSString *const kKeyBadgeCount = @"BadgeCount";
NSString *const kKeyCurrentOrder = @"CurrentOrder";
NSString *const kKeyDeviceToken = @"DeviceToken";
NSString *const kKeyLastCoordinateLat = @"LastCoordinateLat";
NSString *const kKeyLastCoordinateLon = @"LastCoordinateLon";
NSString *const kKeyPresentedIntroductionVersion = @"PresentedIntroductionVersion";
NSString *const kKeyUserCredential = @"UserCredential";


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

// BadgeCount
- (void)setBadgeCount:(NSInteger)count
{
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:kKeyBadgeCount];
}

- (NSInteger)badgeCount
{
    return[[NSUserDefaults standardUserDefaults] integerForKey:kKeyBadgeCount];
}

// IntroductionVersion
- (void)setPresentedIntroductionVersion:(CGFloat)version
{
    [[NSUserDefaults standardUserDefaults] setFloat:version forKey:kKeyPresentedIntroductionVersion];
}

- (CGFloat)presentedIntroductionVersion
{
    return[[NSUserDefaults standardUserDefaults] floatForKey:kKeyPresentedIntroductionVersion];
}

// lastLocation
- (void)setLastCoordinate:(CLLocationCoordinate2D)coordinate
{
    [[NSUserDefaults standardUserDefaults] setDouble:coordinate.latitude forKey:kKeyLastCoordinateLat];
    [[NSUserDefaults standardUserDefaults] setDouble:coordinate.longitude forKey:kKeyLastCoordinateLon];
}

- (CLLocationCoordinate2D)lastCoordinate
{
    CLLocationDegrees lat = [[NSUserDefaults standardUserDefaults] doubleForKey:kKeyLastCoordinateLat];
    CLLocationDegrees lon = [[NSUserDefaults standardUserDefaults] doubleForKey:kKeyLastCoordinateLon];

    // use san francisco city center as default
    if (lat == 0.0 && lon == 0.0)
    {
        lat = 37.7577;
        lon = -122.4376;
    }

    return CLLocationCoordinate2DMake(lat, lon);
}

@end
