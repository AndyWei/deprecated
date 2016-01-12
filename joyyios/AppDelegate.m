//
//  AppDelegate.m
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <AWSCore/AWSCore.h>
#import <AWSS3/AWSS3.h>
#import <Crashlytics/Crashlytics.h>
#import <Fabric/Fabric.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "AppDelegate.h"
#import "Flurry.h"
#import "JYAmazonClientManager.h"
#import "JYButton.h"
#import "JYContactViewController.h"
#import "JYCredentialManager.h"
#import "JYDataStore.h"
#import "JYDeviceManager.h"
#import "JYFilename.h"
#import "JYFriendManager.h"
#import "JYLocalDataManager.h"
#import "JYPhoneNumberViewController.h"
#import "JYProfileCreationViewController.h"
#import "JYProfileViewController.h"
#import "JYSessionListViewController.h"
#import "JYSoundPlayer.h"
#import "JYTimelineViewController.h"
#import "JYUserViewController.h"
#import "JYXmppManager.h"
#import "OnboardingViewController.h"
#import "OnboardingContentViewController.h"

@interface AppDelegate ()
@property (nonatomic) OnboardingContentViewController *page1;
@property (nonatomic) OnboardingContentViewController *page2;
@property (nonatomic) OnboardingContentViewController *page3;
@property (nonatomic) OnboardingViewController *onboardingViewController;
@property (nonatomic) UITabBarController *tabBarController;

@property (nonatomic) JYAmazonClientManager *amazonClientManager;
@property (nonatomic) JYCredentialManager *credentialManager;
@property (nonatomic) JYDeviceManager *deviceManager;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"didFinishLaunchingWithOptions");

    // test only
//    [[JYCredential current] clear];

    // Fabric crashlytics
//    [Fabric with:@[[Crashlytics class]]];
    [Flurry startSession:kFlurryKey];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didManuallySignIn) name:kNotificationDidSignIn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didManuallySignUp) name:kNotificationDidSignUp object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didCreateProfile) name:kNotificationDidCreateProfile object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didFinishContactsConnection) name:kNotificationDidFinishContactsConnection object:nil];

    [self _setupGlobalAppearance];
    [self _launchViewController];
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"applicationDidEnterBackground");
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationAppDidStop object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"applicationWillEnterForeground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive");
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationAppDidStart object:nil];

    // TODO: Implement clear badge number logic in the right places.
    application.applicationIconBadgeNumber = 0;

    [[JYLocalDataManager sharedInstance] start];
    [[JYFriendManager sharedInstance] start];
    [[JYXmppManager sharedInstance] start];

    self.deviceManager =[JYDeviceManager new];
    self.locationManager = [JYLocationManager new];
    self.amazonClientManager = [JYAmazonClientManager new];

    self.credentialManager = [JYCredentialManager new];
    [self.credentialManager start];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"applicationWillTerminate");
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationAppDidStop object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldXmppGoOnline
{
    return self.tabBarController.selectedIndex == 2;
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

    self.deviceManager.deviceToken = token;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)notification
{
    NSLog(@"Notification = %@", notification);
    NSString *notificationType = [notification objectForKey:@"type"];

    if ([notificationType isEqualToString:@"xmpp"])
    {
        [JYSoundPlayer playMessageReceivedAlertWithVibrate:YES];
    }
    else
    {
        NSDictionary *aps = [notification objectForKey:@"aps"];
        NSString *title = aps ? [aps objectForKey:@"alert"] : @"Notification";

        [RKDropdownAlert title:title backgroundColor:FlatGreen textColor:JoyyWhite time:3];
    }
}

#pragma mark - Private methods

- (void)_setupGlobalAppearance
{
    self.window.backgroundColor = JoyyWhitePure;

    [[UINavigationBar appearance] setTintColor:JoyyBlue];
    [[UITabBar appearance] setTintColor:JoyyBlue];
}

- (void)_launchViewController
{
    BOOL needIntroduction = ([JYDataStore sharedInstance].presentedIntroductionVersion < kIntroductionVersion);

    if (needIntroduction)
    {
        [self _launchIntroductionViewController];
        return;
    }

    if ([[JYCredential current] isInvalid])
    {
        [self _launchSignViewController];
        return;
    }

    if ([JYCredential current].yrsValue == 0)
    {
        [self _launchProfileViewController];
        return;
    }

//    [self _launchMainViewController];
    [self _launchContactViewController];
}

- (void)_introductionDidFinish
{
    // Update introduction history to avoid duplicated presenting
    [JYDataStore sharedInstance].presentedIntroductionVersion = kIntroductionVersion;
    [self _launchViewController];
}

- (void)_launchSignViewController
{
    UIViewController *viewController = [JYPhoneNumberViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window.rootViewController = navigationController;
}

- (void)_launchProfileViewController
{
    UIViewController *viewController = [JYProfileCreationViewController new];
    self.window.rootViewController = viewController;
}

- (void)_launchContactViewController
{
    UIViewController *viewController = [JYContactViewController new];
    self.window.rootViewController = viewController;
}

- (void)_launchIntroductionViewController
{
    self.window.rootViewController = self.onboardingViewController;
}

- (void)_launchMainViewController
{
    self.window.rootViewController = self.tabBarController;
    self.onboardingViewController = nil;
}

- (UITabBarController *)tabBarController
{
    if (_tabBarController)
    {
        return _tabBarController;
    }

    _tabBarController = [UITabBarController new];

    UIViewController *vc1 = [JYTimelineViewController new];
    UINavigationController *nc1 = [[UINavigationController alloc] initWithRootViewController:vc1];

    UIViewController *vc2 = [JYUserViewController new];
    UINavigationController *nc2 = [[UINavigationController alloc] initWithRootViewController:vc2];

    UIViewController *vc3 = [JYSessionListViewController new];
    UINavigationController *nc3 = [[UINavigationController alloc] initWithRootViewController:vc3];

    UIViewController *vc4 = [JYProfileViewController new];
    UINavigationController *nc4 = [[UINavigationController alloc] initWithRootViewController:vc4];

    _tabBarController.viewControllers = @[ nc1, nc2, nc3, nc4 ];

    UITabBar *tabBar = _tabBarController.tabBar;
    UITabBarItem *tabBarItem1 = [tabBar.items objectAtIndex:0];
    UITabBarItem *tabBarItem2 = [tabBar.items objectAtIndex:1];
    UITabBarItem *tabBarItem3 = [tabBar.items objectAtIndex:2];
    UITabBarItem *tabBarItem4 = [tabBar.items objectAtIndex:3];

    tabBarItem1.selectedImage = [[UIImage imageNamed:@"home_selected"] imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem1.image = [[UIImage imageNamed:@"home"] imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem1.title = NSLocalizedString(@"Home", nil);

    tabBarItem2.selectedImage = [[UIImage imageNamed:@"people_selected"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem2.image = [[UIImage imageNamed:@"people"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem2.title = NSLocalizedString(@"Radar", nil);

    tabBarItem3.selectedImage = [[UIImage imageNamed:@"chat_selected"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem3.image = [[UIImage imageNamed:@"chat"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem3.title = NSLocalizedString(@"Chat", nil);

    tabBarItem4.selectedImage = [[UIImage imageNamed:@"me_selected"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem4.image = [[UIImage imageNamed:@"me"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem4.title = NSLocalizedString(@"Me", nil);

    return _tabBarController;
}

- (void)_didManuallySignIn
{
    [self.credentialManager start];
    [self _launchMainViewController];
}

- (void)_didManuallySignUp
{
    [self.credentialManager start];
    [self _launchProfileViewController];
}

- (void)_didCreateProfile
{
    [self _launchContactViewController];
}

- (void)_didFinishContactsConnection
{
    [self _launchMainViewController];
}

#pragma mark - Introduction Pages

- (OnboardingViewController *)onboardingViewController
{
    if (_onboardingViewController)
    {
        return _onboardingViewController;
    }

    NSArray *pages = @[ self.page1, self.page2, self.page3 ];
    _onboardingViewController = [OnboardingViewController onboardWithBackgroundImage:[UIImage imageNamed:@"street"] contents:pages];
    _onboardingViewController.shouldFadeTransitions = YES;
    _onboardingViewController.fadePageControlOnLastPage = YES;

    // Allow skipping the onboarding process
    _onboardingViewController.allowSkipping = YES;
    __weak typeof(self) weakSelf = self;
    _onboardingViewController.skipHandler = ^{
        [weakSelf _introductionDidFinish];
    };

    return _onboardingViewController;
}

- (OnboardingContentViewController *)page1
{
    if (_page1)
    {
        return _page1;
    }

    __weak typeof(self) weakSelf = self;
    _page1 = [OnboardingContentViewController contentWithTitle:@"Get Service Anytime Anywhere"
                                                          body:@"People arround you are glad to serve you..."
                                                         image:[UIImage imageNamed:@"blue"]
                                                    buttonText:@"Get Started"
                                                        action:^{
                                                            [weakSelf _introductionDidFinish];
                                                        }];
    return _page1;
}

- (OnboardingContentViewController *)page2
{
    if (_page2)
    {
        return _page2;
    }

    __weak typeof(self) weakSelf = self;
    _page2 = [OnboardingContentViewController contentWithTitle:@"Get Service Anytime Anywhere"
                                                          body:@"People arround you are glad to serve you..."
                                                         image:[UIImage imageNamed:@"blue"]
                                                    buttonText:@"Get Started"
                                                        action:^{
                                                            [weakSelf _introductionDidFinish];
                                                        }];
    _page2.movesToNextViewController = YES;
    return _page2;
}

- (OnboardingContentViewController *)page3
{
    if (_page3)
    {
        return _page3;
    }

    __weak typeof(self) weakSelf = self;
    _page3 = [OnboardingContentViewController contentWithTitle:@"Welcome To Joyy"
                                                          body:@"All men are created equal, that they are endowed by their Creator with certain unalienable Rights, that among these are Life, Liberty, iPhone and \n Joyy."
                                                         image:[UIImage imageNamed:@"yellow"]
                                                    buttonText:@"Get Started"
                                                        action:^{
                                                            [weakSelf _introductionDidFinish];
                                                        }];
    return _page3;
}

@end
