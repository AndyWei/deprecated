//
//  AppDelegate.m
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <BMYScrollableNavigationBar/BMYScrollableNavigationBar.h>

#import "AppDelegate.h"
#import "JYOrderCategoryCollectionViewController.h"
#import "JYIntroduceViewController.h"
#import "JYNearbyViewController.h"
#import "JYSignViewController.h"
#import "User.h"

@interface AppDelegate ()

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
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Private methods

- (void)_setupGlobalAppearance
{
    self.window.backgroundColor = [UIColor whiteColor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_introduceDidFinish) name:kNotificationIntroduceDidFinish object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_signDidFinish) name:kNotificationSignDidFinish object:nil];

    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont lightSystemFontOfSize:kNavBarTitleFontSize], NSFontAttributeName, nil]];

    [[UINavigationBar appearance] setTintColor:JoyyBlue];

    [[UITabBar appearance] setTintColor:JoyyBlue];

    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:kTabBarTitleFontSize], NSFontAttributeName, nil] forState:UIControlStateNormal];

    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:kTabBarTitleFontSize], NSFontAttributeName, nil] forState:UIControlStateSelected];

    [[UITabBarItem appearance] setTitlePositionAdjustment:UIOffsetMake(0.0, -16.0f)];
}

- (void)_setupLocationManager
{
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;

    if([CLLocationManager locationServicesEnabled])
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
    User *user = [User currentUser];
    BOOL userExist = [user load];
    BOOL needIntro = NO;

    if (needIntro)
    {
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        if (userExist && user.tokenExpireTimeInSecs < now)
        {
            [self _automaticSignIn];
        }

        [self _launchIntroViewController];
    }
    else if (!userExist)
    {
        [self _launchSignViewController];
    }
    else
    {
        [self _launchTabViewController];
    }
}

- (void)_introduceDidFinish
{
    User *user = [User currentUser];
    BOOL userExist = [user load];

    //[self _launchTabViewController];
    if (!userExist)
    {
        [self _launchSignViewController];
    }
    else
    {
        [self _launchTabViewController];
    }
}

- (void)_signDidFinish
{
    [self _launchTabViewController];
}

- (void)_launchSignViewController
{
    UIViewController *viewController = [JYSignViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window.rootViewController = navigationController;
}

- (void)_launchIntroViewController
{
    UIViewController *viewController = [JYIntroduceViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window.rootViewController = navigationController;
}

- (void)_launchTabViewController
{
    UIViewController *vc1 = [JYOrderCategoryCollectionViewController new];
    UINavigationController *nc1 = [[UINavigationController alloc] initWithNavigationBarClass:[BMYScrollableNavigationBar class] toolbarClass:nil];
    [nc1 setViewControllers:@[ vc1 ] animated:NO];
    nc1.title = NSLocalizedString(@"I need", nil);

    UIViewController *vc2 = [JYOrderCategoryCollectionViewController new];
    UINavigationController *nc2 = [[UINavigationController alloc] initWithNavigationBarClass:[BMYScrollableNavigationBar class] toolbarClass:nil];
    [nc2 setViewControllers:@[ vc2 ] animated:NO];
    nc2.title = NSLocalizedString(@"I can", nil);

    UITabBarController *tabBarController = [UITabBarController new];
    tabBarController.viewControllers = [NSArray arrayWithObjects:nc1, nc2, nil];

    self.window.rootViewController = tabBarController;
}

// signin in the background
- (void)_automaticSignIn
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:[User currentUser].email password:[User currentUser].password];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlApiBase, @"signin"];

    [manager GET:url
        parameters:nil
        success:^(AFHTTPRequestOperation *operation, id responseObject) {
          [User currentUser].credential = responseObject;

        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          NSLog(@"_automaticSignIn Error: %@", error);
        }];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.currentLocation = [locations lastObject];
    [self.locationManager stopUpdatingLocation];
//    CLGeocoder *geocoder = [[CLGeocoder alloc] init] ;
//    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error)
//     {
//         if (!(error))
//         {
//             CLPlacemark *placemark = [placemarks objectAtIndex:0];
//             NSLog(@"\nCurrent Location Detected\n");
//             NSLog(@"placemark %@",placemark);
//             NSString *locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
//             NSString *Address = [[NSString alloc]initWithString:locatedAt];
//             NSString *Area = [[NSString alloc]initWithString:placemark.locality];
//             NSString *Country = [[NSString alloc]initWithString:placemark.country];
//             NSString *CountryArea = [NSString stringWithFormat:@"%@, %@", Area,Country];
//             NSLog(@"%@",CountryArea);
//         }
//         else
//         {
//             NSLog(@"Geocode failed with error %@", error);
//             NSLog(@"\nCurrent Location Not Detected\n");
//             //return;
//             CountryArea = NULL;
//         }
//         /*---- For more results
//          placemark.region);
//          placemark.country);
//          placemark.locality);
//          placemark.name);
//          placemark.ocean);
//          placemark.postalCode);
//          placemark.subLocality);
//          placemark.location);
//          ------*/
//     }];
}
@end
