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

+ (JYDeviceManager *)sharedInstance
{
    static JYDeviceManager *_sharedInstance = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedInstance = [JYDeviceManager new];
    });

    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:kDeviceToken];
        _badgeCount = [[NSUserDefaults standardUserDefaults] integerForKey:kBadgeCount];

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

- (void)setDeviceToken:(NSString *)deviceToken
{
//    if ([_deviceToken isEqualToString:deviceToken]) {
//        return;
//    }

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
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
    else
    {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
}

- (void)_registerDeviceToken:(NSString *)deviceToken
{
    NSDictionary *parameters = @{ @"dtoken": deviceToken, @"pns": @1 };
    NSString *url = [NSString apiURLWithPath:@"device/register"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager managerWithToken];

    [manager POST:url
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"POST device/register Success");
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"POST device/register error: %@", error);
          }];
    
}

@end
