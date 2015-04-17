//
//  AppDelegate.m
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>

#import "AppDelegate.h"
#import "JYOrderCategoryCollectionViewController.h"
#import "JYNearbyViewController.h"
#import "JYSignViewController.h"
#import "JYUser.h"
#import "OnboardingViewController.h"
#import "OnboardingContentViewController.h"

@interface AppDelegate ()

@property (nonatomic) NSTimer *signInTimer;

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

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
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your
    // application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the
    // background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the
    // background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private methods

- (void)_setupGlobalAppearance
{
    self.window.backgroundColor = [UIColor whiteColor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_signDidFinish) name:kNotificationSignDidFinish object:nil];

    [[UINavigationBar appearance]
        setTitleTextAttributes:[NSDictionary
                                   dictionaryWithObjectsAndKeys:[UIFont lightSystemFontOfSize:kNavBarTitleFontSize], NSFontAttributeName, nil]];

    [[UINavigationBar appearance] setTintColor:JoyyBlue];

    [[UITabBar appearance] setTintColor:JoyyBlue];

    [[UITabBarItem appearance]
        setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:kTabBarTitleFontSize], NSFontAttributeName, nil]
                      forState:UIControlStateNormal];

    [[UITabBarItem appearance]
        setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:kTabBarTitleFontSize], NSFontAttributeName, nil]
                      forState:UIControlStateSelected];

    [[UITabBarItem appearance] setTitlePositionAdjustment:UIOffsetMake(0.0, -16.0f)];
}

- (void)_setupLocationManager
{
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
    BOOL needIntro = NO;

    if (needIntro)
    {
        [self _launchIntroViewController];
    }
    else if ([user exists])
    {
        [self _launchTabViewController];
    }
    else
    {
        [self _launchSignViewController];
    }
}

- (void)_introductionDidFinish
{
    JYUser *user = [JYUser currentUser];

    if ([user exists])
    {
        [self _launchTabViewController];
    }
    else
    {
        [self _launchSignViewController];
    }
}

- (void)_signDidFinish
{
    [self _signInPeriodically:kSignIntervalMax];
    [self _launchTabViewController];
}

- (void)_signInPeriodically:(CGFloat)interval
{
    if (self.signInTimer)
    {
        [self.signInTimer invalidate];
    }

    self.signInTimer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(_autoSignIn:) userInfo:nil repeats:NO];
}

- (void)_launchSignViewController
{
    UIViewController *viewController = [JYSignViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window.rootViewController = navigationController;
}

- (void)_launchIntroViewController
{
    self.window.rootViewController = [self _onboardingViewController];
}

- (void)_launchTabViewController
{
    JYUser *user = [JYUser currentUser];
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

    NSAssert([user exists], @"The user credential should be there when _launchTabViewController is called");

    if (user.tokenExpireTimeInSecs < now)
    {
        if (self.signInTimer)
        {
            [self.signInTimer invalidate];
            self.signInTimer = nil;
        }
        [self _autoSignIn:nil];
    }
    else if (!self.signInTimer)
    {
        [self _signInPeriodically:(user.tokenExpireTimeInSecs - now)];
    }

    UIViewController *vc1 = [JYOrderCategoryCollectionViewController new];
    UINavigationController *nc1 = [[UINavigationController alloc] initWithRootViewController:vc1];
    nc1.title = NSLocalizedString(@"I need", nil);

    UIViewController *vc2 = [JYNearbyViewController new];
    UINavigationController *nc2 = [[UINavigationController alloc] initWithRootViewController:vc2];
    nc2.title = NSLocalizedString(@"I can", nil);

    UITabBarController *tabBarController = [UITabBarController new];
    tabBarController.viewControllers = @[ nc1, nc2 ];

    self.window.rootViewController = tabBarController;
}

// signin in the background
- (void)_autoSignIn:(NSTimer*)timer
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:[JYUser currentUser].email password:[JYUser currentUser].password];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"signin"];

    NSLog(@"_autoSignIn start");
    NSLog(@"email = %@", [JYUser currentUser].email);
    NSLog(@"password = %@", [JYUser currentUser].password);

    __weak typeof(self) weakSelf = self;
    [manager GET:url
        parameters:nil
        success:^(AFHTTPRequestOperation *operation, id responseObject)
        {
            NSLog(@"_autoSignIn Success");
            [JYUser currentUser].credential = responseObject;
            [weakSelf _signInPeriodically:kSignIntervalMax];
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error)
        {
            NSLog(@"_autoSignIn Error: %@", error);
            [weakSelf _signInPeriodically:kSignIntervalMin];
        }];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.currentLocation = [locations lastObject];
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
    OnboardingContentViewController *page = [OnboardingContentViewController
        contentWithTitle:@"What A Beautiful Photo"
                    body:@"This city background image is so beautiful."
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
    OnboardingContentViewController *page = [OnboardingContentViewController
        contentWithTitle:@"I'm so sorry"
                    body:@"I can't get over the nice blurry background photo."
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
    OnboardingContentViewController *page = [OnboardingContentViewController contentWithTitle:@"Seriously Though"
                                                                                         body:@"Kudos to the photographer."
                                                                                        image:[UIImage imageNamed:@"yellow"]
                                                                                   buttonText:@"Get Started"
                                                                                       action:^{
                                                                                           [weakSelf _introductionDidFinish];
                                                                                       }];
    return page;
}

@end
