//
//  JYDeviceManager.m
//  joyyios
//
//  Created by Ping Yang on 11/4/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYDeviceManager.h"

@interface JYDeviceManager ()
@end

NSString *const kDeviceToken = @"device_token";

@implementation JYDeviceManager

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:kDeviceToken];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_apiTokenReady) name:kNotificationAPITokenReady object:nil];
    }
    return self;
}

- (void)start
{
    NSLog(@"DeviceManager started");
}

- (void)_apiTokenReady
{
    [self _registerPushNotification];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_registerPushNotification
{
    UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

- (void)setDeviceToken:(NSString *)deviceToken
{
    _deviceToken = deviceToken;
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:kDeviceToken];

    [self _registerDeviceToken:deviceToken];
}

- (void)updateDeviceBadgeCount:(NSInteger)count
{
    NSDictionary *parameters = @{ @"count": @(count) };
    NSString *url = [NSString apiURLWithPath:@"device/badge"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    [manager POST:url
       parameters:parameters
         progress:nil
          success:^(NSURLSessionTask *operation, id responseObject) {
              NSLog(@"POST device/badge Success");
          }
          failure:^(NSURLSessionTask *operation, NSError *error) {
              NSLog(@"POST device/badge error: %@", error);
          }];
}

- (void)_registerDeviceToken:(NSString *)deviceToken
{
    NSDictionary *parameters = @{ @"dtoken": deviceToken, @"service": @(kAPN) };
    NSString *url = [NSString apiURLWithPath:@"device/register"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    [manager POST:url
       parameters:parameters
         progress:nil
          success:^(NSURLSessionTask *operation, id responseObject) {
              NSLog(@"POST device/register Success");
          }
          failure:^(NSURLSessionTask *operation, NSError *error) {
              NSLog(@"POST device/register error: %@", error);
          }];
}

@end
