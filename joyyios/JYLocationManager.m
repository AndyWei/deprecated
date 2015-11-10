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

@interface JYLocationManager () <CLLocationManagerDelegate, UIAlertViewDelegate>
@property (nonatomic) CLLocationManager *manager;
@property (nonatomic) BOOL apiTokenReady;
@end

NSString *const kCountryCode = @"location_country_code";
NSString *const kZip = @"location_zip";

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

        _apiTokenReady = NO;
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
    _apiTokenReady = YES;

    if ([JYUser me].yrs > 0)
    {
        [self _readLocation];
    }
}

- (void)_userYRSReady
{
    if (self.apiTokenReady)
    {
        [self _readLocation];
    }
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


    if ([self.manager respondsToSelector:@selector(requestWhenInUseAuthorization)])
    {
        [self.manager requestWhenInUseAuthorization];
        return;
    }

    NSString *title = NSLocalizedString(@"Hey, WinkRock need your location to search people nearby", nil);
    NSString *message = NSLocalizedString(@"You can allow it in 'Settings -> Privacy -> Location Services'", nil);

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"Settings", nil), nil];
    [alertView show];
}

- (void)setCountryCode:(NSString *)countryCode
{
    _countryCode = countryCode;
    [[NSUserDefaults standardUserDefaults] setObject:countryCode forKey:kCountryCode];
}


- (void)setZip:(NSString *)zip
{
    [[NSUserDefaults standardUserDefaults] setObject:zip forKey:kZip];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        // Send the user to the Settings
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:settingsURL];
    }
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
                           NSLog(@"Geocode failed with error %@", error);
                       }
                       else
                       {
                           CLPlacemark *placemark = [placemarks lastObject];
                           [weakSelf _updateZipWithPlacemark:placemark];
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
    NSString *countryCode = placemark.ISOcountryCode;
    NSString *zip = placemark.postalCode;

    if (![zip isEqualToString:self.zip] || ![countryCode isEqualToString:self.countryCode])
    {
        self.zip = zip;
        self.countryCode = countryCode;
        [self _appearInZip:zip country:countryCode];
    }
}

- (void)_appearInZip:(NSString *)zip country:(NSString *)countryCode
{
    NSUInteger yrs = [JYUser me].yrs;
    NSDictionary *parameters = @{ @"zip": zip, @"country": countryCode, @"yrs": @(yrs) };
    NSString *url = [NSString apiURLWithPath:@"user/appear"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager managerWithToken];

    [manager POST:url
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"POST user/appear Success");
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"user/appear error: %@", error);
          }];
    
}

@end
