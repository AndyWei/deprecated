//
//  JYDataStore.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYDataStore.h"

NSString *const kKeyBadgeCount = @"BadgeCount";
NSString *const kKeyDeviceToken = @"DeviceToken";
NSString *const kKeyLastCoordinateLat = @"LastCoordinateLat";
NSString *const kKeyLastCoordinateLon = @"LastCoordinateLon";
NSString *const kKeyLastCellId = @"LastCellId";
NSString *const kKeyPresentedIntroductionVersion = @"PresentedIntroductionVersion";

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

// DeviceToken
- (void)setDeviceToken:(NSString *)token
{
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:kKeyDeviceToken];
}

- (NSString *)deviceToken
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kKeyDeviceToken];
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

// lastCellId
- (void)setLastCellId:(NSString *)cellId
{
    [[NSUserDefaults standardUserDefaults] setObject:cellId forKey:kKeyLastCellId];
}

- (NSString *)lastCellId
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kKeyLastCellId];

}

@end
