//
//  JYLocationManager.m
//  joyyios
//
//  Created by Ping Yang on 11/2/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import "JYLocationManager.h"
#import "JYUser.h"
#import "JYYRS.h"

@interface JYLocationManager () <CLLocationManagerDelegate>
@property (nonatomic) CLLocationManager *manager;
@property (nonatomic) CLPlacemark *lastPlacemark;
@end

static NSString *const kCountryCode = @"location_country_code";
static NSString *const kZip = @"location_zip";

@implementation JYLocationManager

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // use SIM card country code as default country code
        _countryCode = [[NSUserDefaults standardUserDefaults] stringForKey:kCountryCode];
        if (_countryCode)
        {
            CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
            CTCarrier *carrier = [netInfo subscriberCellularProvider];
            _countryCode = [carrier.isoCountryCode uppercaseString];
        }

        _zip = [[NSUserDefaults standardUserDefaults] stringForKey:kZip];
        if (!_zip)
        {
            _zip = @"AAAA";
        }

        _manager = [CLLocationManager new];
        _manager.delegate = self;
        _manager.distanceFilter = kCLDistanceFilterNone;
        _manager.desiredAccuracy = kCLLocationAccuracyHundredMeters;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_apiTokenReady) name:kNotificationAPITokenReady object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_userYRSReady) name:kNotificationUserYRSReady object:nil];
    }
    return self;
}

- (void)start
{
    NSLog(@"LocationManager started");
}

- (void)_apiTokenReady
{
    [self _readLocation];
}

- (void)_userYRSReady
{
    [self _updateZipWithPlacemark:self.lastPlacemark];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_readLocation
{
    if (![CLLocationManager locationServicesEnabled])
    {
        return;
    }

    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied &&
        [CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined)
    {
        [self.manager startUpdatingLocation];
        return;
    }

    [self.manager requestWhenInUseAuthorization];
}

- (void)setCountryCode:(NSString *)countryCode
{
    _countryCode = countryCode;
    [[NSUserDefaults standardUserDefaults] setObject:countryCode forKey:kCountryCode];
}


- (void)setZip:(NSString *)zip
{
    _zip = zip;
    [[NSUserDefaults standardUserDefaults] setObject:zip forKey:kZip];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    __weak typeof(self) weakSelf = self;
    [geocoder reverseGeocodeLocation:location
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       if (error)
                       {
//                           NSLog(@"Geocode failed with error %@", error);
                       }
                       else
                       {
                           weakSelf.lastPlacemark = [placemarks lastObject];
                           [weakSelf _updateZipWithPlacemark:weakSelf.lastPlacemark];
                       }
                   }];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusDenied)
    {
        return;
    }

    [self.manager startUpdatingLocation];
}

#pragma mark - Geo

- (void)_updateZipWithPlacemark:(CLPlacemark *)placemark
{
    if (!placemark)
    {
        return;
    }

    NSString *countryCode = placemark.ISOcountryCode;
    NSString *zip = placemark.postalCode;

    if (!countryCode || [countryCode isEqualToString:self.countryCode])
    {
        return;
    }

    if (!zip || [zip isEqualToString:self.zip])
    {
        return;
    }

    self.zip = zip;
    self.countryCode = countryCode;

    if ([JYCredential current].yrsValue == 0 || [JYCredential current].tokenValidInSeconds <= 0)
    {
        return;
    }
    
    [self _appearInZip:zip country:countryCode];
}

- (void)_appearInZip:(NSString *)zip country:(NSString *)countryCode
{
    NSDictionary *parameters = @{ @"zip": zip, @"country": countryCode, @"yrs": @([JYCredential current].yrsValue) };
    NSString *url = [NSString apiURLWithPath:@"user/appear"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    [manager POST:url
       parameters:parameters
         progress:nil
          success:^(NSURLSessionTask *operation, id responseObject) {
              NSLog(@"POST user/appear Success. zip = %@", zip);
          }
          failure:^(NSURLSessionTask *operation, NSError *error) {
              NSLog(@"POST user/appear error: %@", error);
          }];
}

@end
