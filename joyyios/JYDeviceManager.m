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
NSString *const kBadgeCount = @"badge_count";

@implementation JYDeviceManager

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:kDeviceToken];
        _badgeCount = [[NSUserDefaults standardUserDefaults] integerForKey:kBadgeCount];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_apiTokenReady) name:kNotificationAPITokenReady object:nil];

        NSLog(@"DeviceManager created");
    }
    return self;
}

- (void)_apiTokenReady
{
    [self _registerPushNotification];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setDeviceToken:(NSString *)deviceToken
{
    if ([deviceToken isEqualToString:_deviceToken])
    {
        return;
    }

    _deviceToken = deviceToken;
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:kDeviceToken];

    [self _registerDeviceToken:deviceToken];
}

- (void)setBadgeCount:(NSInteger)count
{
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:kBadgeCount];
}

- (void)_registerPushNotification
{
    UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

- (void)_registerDeviceToken:(NSString *)deviceToken
{
    NSDictionary *parameters = @{ @"dtoken": deviceToken, @"pns": @(kAPN) };
    NSString *url = [NSString apiURLWithPath:@"device/register"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    [manager POST:url
       parameters:parameters
          success:^(NSURLSessionTask *operation, id responseObject) {
              NSLog(@"POST device/register Success");
          }
          failure:^(NSURLSessionTask *operation, NSError *error) {
              NSLog(@"POST device/register error: %@", error);
          }];
    
}

@end
