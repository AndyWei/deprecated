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
#import "JYHomeViewController.h"
#import "JYIntroViewController.h"
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

- (void)_setupGlobalAppearance
{
    self.window.backgroundColor = [UIColor whiteColor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_introDidFinish) name:kNotificationIntroDidFinish object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_signDidFinish) name:kNotificationSignDidFinish object:nil];

    [[UINavigationBar appearance]
        setTitleTextAttributes:[NSDictionary
                                   dictionaryWithObjectsAndKeys:[UIFont lightSystemFontOfSize:kNavBarTitleFontSize], NSFontAttributeName, nil]];

    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont lightSystemFontOfSize:kTabBarTitleFontSize],
                                                                                                 NSFontAttributeName, nil]
                                             forState:UIControlStateNormal];

    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont lightSystemFontOfSize:kTabBarTitleFontSize],
                                                                                                 NSFontAttributeName, nil]
                                             forState:UIControlStateSelected];

    [[UITabBarItem appearance] setTitlePositionAdjustment:UIOffsetMake(0.0, -16.0f)];
}

- (void)_launchViewController
{
    User *user = [User currentUser];
    BOOL userExist = [user load];
    BOOL needIntro = YES;

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

- (void)_introDidFinish
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
    UIViewController *viewController = [JYIntroViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window.rootViewController = navigationController;
}

- (void)_launchTabViewController
{
    UIViewController *vc1 = [JYHomeViewController new];
    UINavigationController *nc1 = [[UINavigationController alloc] initWithNavigationBarClass:[BMYScrollableNavigationBar class] toolbarClass:nil];
    [nc1 setViewControllers:@[ vc1 ] animated:NO];
    nc1.title = NSLocalizedString(@"I need", nil);

    UIViewController *vc2 = [JYHomeViewController new];
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

@end
