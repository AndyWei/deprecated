//
//  AppDelegate.m
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <MSWeakTimer/MSWeakTimer.h>
#import <RKDropdownAlert/RKDropdownAlert.h>
#import <Stripe/Stripe.h>

#import "AppDelegate.h"
#import "JYDataStore.h"
#import "JYAnonymousViewController.h"
#import "JYMenuViewController.h"
#import "JYMapViewController.h"
#import "JYSignViewController.h"
#import "JYUser.h"
#import "OnboardingViewController.h"
#import "OnboardingContentViewController.h"

@interface AppDelegate ()

@property(nonatomic) MSWeakTimer *signInTimer;
@property (nonatomic) dispatch_queue_t backgroundQueue;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"didFinishLaunchingWithOptions");

    self.cellId = [JYDataStore sharedInstance].lastCellId ? [JYDataStore sharedInstance].lastCellId : @"94555"; // default zipcode
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_signDidFinish) name:kNotificationDidSignIn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_signDidFinish) name:kNotificationDidSignUp object:nil];

    [self _setupGlobalAppearance];
    [self _setupLocationManager];
    [self _launchViewController];

    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as
    // an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the
    // game.
    NSLog(@"applicationWillResignActive");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your
    // application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"applicationDidEnterBackground");
    if (self.signInTimer)
    {
        [self.signInTimer invalidate];
        self.signInTimer = nil;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the
    // background.
    NSLog(@"applicationWillEnterForeground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the
    // background, optionally refresh the user interface.

    NSLog(@"applicationDidBecomeActive");
    JYUser *user = [JYUser currentUser];
    if(![user exists])
    {
        return;
    }

    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (user.tokenExpireTimeInSecs < now)
    {
        if (self.signInTimer)
        {
            [self.signInTimer invalidate];
            self.signInTimer = nil;
        }

        [self _autoSignIn];
    }
    else
    {
        [self _signInAfter:(user.tokenExpireTimeInSecs - now)];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"applicationWillTerminate");
    if (self.signInTimer)
    {
        [self.signInTimer invalidate];
        self.signInTimer = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Properties

- (dispatch_queue_t)backgroundQueue
{
    if (!_backgroundQueue)
    {
        _backgroundQueue = dispatch_queue_create("com.joyyapp.background_queue", DISPATCH_QUEUE_CONCURRENT);
    }
    return _backgroundQueue;
}

#pragma mark - Notifications

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];

    [JYDataStore sharedInstance].deviceToken = token;
    [self _uploadDeviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)notification
{
    NSLog(@"Notification = %@", notification);

    NSDictionary *aps = [notification objectForKey:@"aps"];
    NSString *title = aps ? [aps objectForKey:@"alert"] : @"Notification";

    [RKDropdownAlert title:title backgroundColor:FlatGreen textColor:JoyyWhite time:3];
}

#pragma mark - Private methods

- (void)_setupGlobalAppearance
{
    self.window.backgroundColor = [UIColor whiteColor];

    [[UINavigationBar appearance] setTintColor:JoyyBlue];
    [[UITabBar appearance] setTintColor:JoyyBlue];

//    [[UINavigationBar appearance]
//        setTitleTextAttributes:[NSDictionary
//                                   dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:kNavBarTitleFontSize], NSFontAttributeName, nil]];


//    [[UITabBarItem appearance]
//        setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:kTabBarTitleFontSize], NSFontAttributeName, nil]
//                      forState:UIControlStateNormal];
//
//    [[UITabBarItem appearance]
//        setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:kTabBarTitleFontSize], NSFontAttributeName, nil]
//                      forState:UIControlStateSelected];

//    [[UITabBarItem appearance] setTitlePositionAdjustment:UIOffsetMake(0.0, -10.0f)];
}

- (void)_setupLocationManager
{
    // use last location before we get current one
    self.currentCoordinate = [JYDataStore sharedInstance].lastCoordinate;

    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;

    if ([CLLocationManager locationServicesEnabled])
    {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
        {
            if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
            {
                [self.locationManager requestWhenInUseAuthorization];
            }
            else
            {
                NSString *title = NSLocalizedString(@"Hey, Joyy need your location", nil);
                NSString *message = NSLocalizedString(@"You can allow it in 'Settings -> Privacy -> Location Services'", nil);

                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                                    message:message
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                          otherButtonTitles:NSLocalizedString(@"Settings", nil), nil];
                [alertView show];
            }
        }
        else
        {
            [self.locationManager startUpdatingLocation];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        // Send the user to the Settings for this app
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:settingsURL];
    }
}

- (void)_launchViewController
{
    JYUser *user = [JYUser currentUser];

    BOOL needIntro = ([JYDataStore sharedInstance].presentedIntroductionVersion < kIntroductionVersion);

    if (needIntro)
    {
        [self _launchIntroductionViewController];
    }
    else if ([user exists])
    {
        [self _launchMainViewController];
    }
    else
    {
        [self _launchSignViewController];
    }
}

- (void)_registerPushNotifications
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

- (void)_introductionDidFinish
{
    // Store introduction history
    [JYDataStore sharedInstance].presentedIntroductionVersion = kIntroductionVersion;

    [self _launchViewController];
}

- (void)_launchSignViewController
{
    UIViewController *viewController = [JYSignViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window.rootViewController = navigationController;
}

- (void)_launchIntroductionViewController
{
    self.window.rootViewController = [self _onboardingViewController];
}

- (void)_launchMainViewController
{
    UIViewController *vc1 = [JYAnonymousViewController new];
    UINavigationController *nc1 = [[UINavigationController alloc] initWithRootViewController:vc1];

    UIViewController *vc2 = [JYMenuViewController new];
    UINavigationController *nc2 = [[UINavigationController alloc] initWithRootViewController:vc2];

    UIViewController *vc3 = [JYMenuViewController new];
    UINavigationController *nc3 = [[UINavigationController alloc] initWithRootViewController:vc3];

    UIViewController *vc4 = [JYMenuViewController new];
    UINavigationController *nc4 = [[UINavigationController alloc] initWithRootViewController:vc4];

    UITabBarController *tabBarController = [UITabBarController new];
    tabBarController.viewControllers = @[ nc1, nc2, nc3, nc4 ];

    UITabBar *tabBar = tabBarController.tabBar;
    UITabBarItem *tabBarItem1 = [tabBar.items objectAtIndex:0];
    UITabBarItem *tabBarItem2 = [tabBar.items objectAtIndex:1];
    UITabBarItem *tabBarItem3 = [tabBar.items objectAtIndex:2];
    UITabBarItem *tabBarItem4 = [tabBar.items objectAtIndex:3];

    tabBarItem1.selectedImage = [[UIImage imageNamed:@"mask_selected"] imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem1.image = [[UIImage imageNamed:@"mask"] imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem1.title = NSLocalizedString(@"Anonymous", nil);

    tabBarItem2.selectedImage = [[UIImage imageNamed:@"search_selected"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem2.image = [[UIImage imageNamed:@"search"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem2.title = NSLocalizedString(@"Search", nil);

    tabBarItem3.selectedImage = [[UIImage imageNamed:@"chat_selected"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem3.image = [[UIImage imageNamed:@"chat"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem3.title = NSLocalizedString(@"Chat", nil);

    tabBarItem4.selectedImage = [[UIImage imageNamed:@"me_selected"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem4.image = [[UIImage imageNamed:@"me"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem4.title = NSLocalizedString(@"Me", nil);

    self.window.rootViewController = tabBarController;
}

- (void)_signDidFinish
{
    [self _registerPushNotifications];
    [self _signInAfter:k30Minutes];
    [self _launchMainViewController];
}

- (void)_signInAfter:(NSTimeInterval)interval
{
    if (self.signInTimer)
    {
        [self.signInTimer invalidate];
    }

    self.signInTimer = [MSWeakTimer scheduledTimerWithTimeInterval:interval
                                                            target:self
                                                          selector:@selector(_autoSignIn)
                                                          userInfo:nil
                                                           repeats:NO
                                                     dispatchQueue:self.backgroundQueue];
}

#pragma mark - Network

- (void)_autoSignIn
{
    NSString *email = [JYUser currentUser].email;
    NSString *password = [JYUser currentUser].password;
    if (!email || !password)
    {
        return;
    }

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:email password:password];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"signin"];

    NSLog(@"_autoSignIn start");
    NSLog(@"email = %@", email);
    NSLog(@"password = %@", password);

    __weak typeof(self) weakSelf = self;
    [manager GET:url
        parameters:nil
        success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"_autoSignIn Success");
            [JYUser currentUser].credential = responseObject;
            [weakSelf _signInAfter:k30Minutes];

            // Register push notification now to trigger device token uploading, which is to avoid server side device token lost unexpectedly
            [weakSelf _registerPushNotifications];
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"_autoSignIn Error: %@", error);
            [weakSelf _signInAfter:k1Minutes];
        }];
}

- (void)_uploadDeviceToken
{
    NSString *deviceToken = [JYDataStore sharedInstance].deviceToken;
    if (!deviceToken)
    {
        return;
    }

    NSInteger badgeCount = [JYDataStore sharedInstance].badgeCount;

    NSDictionary *parameters = @{@"service": @(kAPN), @"device": deviceToken, @"badge": @(badgeCount)};
    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"person/device"];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    [manager POST:url
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"DeviceToken upload Success responseObject: %@", responseObject);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"DeviceToken Upload Error: %@", error);
          }];
    
}

- (void)_updateGeoInfo
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:self.currentCoordinate.latitude longitude:self.currentCoordinate.longitude];
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
                           [weakSelf _updateCellIdWithPlacemark:placemark];
                       }
                   }];
}

- (void)_updateCellIdWithPlacemark:(CLPlacemark *)placemark
{
    NSString *newCellId = nil;
    if ([placemark.ISOcountryCode isEqualToString:@"US"])
    {
        newCellId = placemark.postalCode;
    }
    else
    {
        newCellId = [NSString stringWithFormat:@"%@%@", placemark.ISOcountryCode, placemark.postalCode];
    }

    if (![newCellId isEqualToString:self.cellId])
    {
        self.cellId = newCellId;
        [JYDataStore sharedInstance].lastCellId = newCellId;
        [self _uploadLocation];
    }
}

- (void)_uploadLocation
{
    CLLocationCoordinate2D coods = self.currentCoordinate;
    NSDictionary *parameters = @{@"lon": @(coods.longitude), @"lat": @(coods.latitude), @"cell": self.cellId};
    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"person/location"];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    [manager POST:url
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"Location upload Success responseObject: %@", responseObject);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Location Upload Error: %@", error);
          }];
    
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *currentLocation = [locations lastObject];
    self.currentCoordinate = currentLocation.coordinate;
    [JYDataStore sharedInstance].lastCoordinate = self.currentCoordinate;
    [self _updateGeoInfo];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusDenied)
    {
        return;
    }

    [self.locationManager startUpdatingLocation];
}

#pragma mark - Introduction Pages

- (OnboardingViewController *)_onboardingViewController
{
    NSArray *pages = @[ [self _page1], [self _page2], [self _page3] ];
    OnboardingViewController *onboardingVC = [OnboardingViewController onboardWithBackgroundImage:[UIImage imageNamed:@"street"] contents:pages];
    onboardingVC.shouldFadeTransitions = YES;
    onboardingVC.fadePageControlOnLastPage = YES;

    // Allow skipping the onboarding process
    onboardingVC.allowSkipping = YES;
    __weak typeof(self) weakSelf = self;
    onboardingVC.skipHandler = ^{
        [weakSelf _introductionDidFinish];
    };
    return onboardingVC;
}

- (OnboardingContentViewController *)_page1
{
    __weak typeof(self) weakSelf = self;
    OnboardingContentViewController *page = [OnboardingContentViewController contentWithTitle:@"Get Service Anytime Anywhere"
                                                                                         body:@"People arround you are glad to serve you..."
                                                                                        image:[UIImage imageNamed:@"blue"]
                                                                                   buttonText:@"Get Started"
                                                                                       action:^{
                                                                                           [weakSelf _introductionDidFinish];
                                                                                       }];
    return page;
}

- (OnboardingContentViewController *)_page2
{
    __weak typeof(self) weakSelf = self;
    OnboardingContentViewController *page = [OnboardingContentViewController contentWithTitle:@"In Joyy People Help Each Other"
                                                                                         body:@"You can provide service too, and get paid"
                                                                                        image:[UIImage imageNamed:@"red"]
                                                                                   buttonText:@"Get Started"
                                                                                       action:^{
                                                                                           [weakSelf _introductionDidFinish];
                                                                                       }];
    page.movesToNextViewController = YES;

    return page;
}

- (OnboardingContentViewController *)_page3
{
    __weak typeof(self) weakSelf = self;
    OnboardingContentViewController *page = [OnboardingContentViewController contentWithTitle:@"Welcome To Joyy"
                                                                                         body:@"All men are created equal, that they are endowed by their Creator with certain unalienable Rights, that among these are Life, Liberty, iPhone and \n Joyy Account."
                                                                                        image:[UIImage imageNamed:@"yellow"]
                                                                                   buttonText:@"Get Started"
                                                                                       action:^{
                                                                                           [weakSelf _introductionDidFinish];
                                                                                       }];
    return page;
}

@end
