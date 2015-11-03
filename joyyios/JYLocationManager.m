//
//  JYLocationManager.m
//  joyyios
//
//  Created by Andy Wei on 11/2/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYLocationManager.h"

@interface JYDataStore ()
@end

NSString *const kKeyLastCoordinateLat = @"LastCoordinateLat";
NSString *const kKeyLastCoordinateLon = @"LastCoordinateLon";
NSString *const kKeyLastZip = @"LastZip";

@implementation JYLocationManager

+ (JYLocationManager *)sharedInstance
{
    static JYLocationManager *_sharedInstance = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedInstance = [JYLocationManager new];
    });

    return _sharedInstance;
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

// lastZip
- (void)setLastZip:(NSString *)zip
{
    [[NSUserDefaults standardUserDefaults] setObject:zip forKey:kKeyLastZip];
}

- (NSString *)lastZip
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kKeyLastZip];
    
}

@end
