//
//  JYDataStore.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYDataStore.h"


NSString *const kKeyAPITokenExpireTime = @"APITokenExpireTime";
NSString *const kKeyBadgeCount = @"BadgeCount";
NSString *const kKeyCurrentInvite = @"CurrentInvite";
NSString *const kKeyDefaultCardNumber = @"DefaultCardNumber";
NSString *const kKeyDefaultCustomerId = @"DefaultCustomerId";
NSString *const kKeyDeviceToken = @"DeviceToken";
NSString *const kKeyLastCoordinateLat = @"LastCoordinateLat";
NSString *const kKeyLastCoordinateLon = @"LastCoordinateLon";
NSString *const kKeyLastZipcode = @"LastZipcode";
NSString *const kKeyPresentedIntroductionVersion = @"PresentedIntroductionVersion";
NSString *const kKeyUserCredential = @"UserCredential";


@implementation JYDataStore

+ (instancetype)sharedInstance
{
    static JYDataStore *_sharedInstance = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedInstance = [JYDataStore new];
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

// CurrentInvite
- (void)setCurrentInvite:(JYInvite *)order
{
    [[NSUserDefaults standardUserDefaults] setObject:order forKey:kKeyCurrentInvite];
}

- (JYInvite *)currentInvite
{
    JYInvite *order = nil;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kKeyCurrentInvite])
    {
        order = [[NSUserDefaults standardUserDefaults] objectForKey:kKeyCurrentInvite];
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
    return [[NSUserDefaults standardUserDefaults] stringForKey:kKeyDeviceToken];
}

// DefaultCardNumber
- (void)setDefaultCardNumber:(NSString *)defaultCardNumber
{
    [[NSUserDefaults standardUserDefaults] setObject:defaultCardNumber forKey:kKeyDefaultCardNumber];
}

- (NSString *)defaultCardNumber
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kKeyDefaultCardNumber];

}

// DefaultCustomerId
- (void)setDefaultCustomerId:(NSString *)defaultCustomerId
{
    [[NSUserDefaults standardUserDefaults] setObject:defaultCustomerId forKey:kKeyDefaultCustomerId];
}

- (NSString *)defaultCustomerId
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kKeyDefaultCustomerId];

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

// lastZipcode
- (void)setLastZipcode:(NSString *)zipcode
{
    [[NSUserDefaults standardUserDefaults] setObject:zipcode forKey:kKeyLastZipcode];
}

- (NSString *)lastZipcode
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kKeyLastZipcode];

}

@end
