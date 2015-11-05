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
#import <KVNProgress/KVNProgress.h>
#import <MSWeakTimer/MSWeakTimer.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "AppDelegate.h"
#import "JYAmazonClientManager.h"
#import "JYButton.h"
#import "JYDeviceManager.h"
#import "JYFilename.h"
#import "JYMasqueradeViewController.h"
#import "JYLocationManager.h"
#import "JYPeopleViewController.h"
#import "JYSessionListViewController.h"
#import "JYPhoneNumberViewController.h"
#import "JYSoundPlayer.h"
#import "JYXmppManager.h"
#import "Flurry.h"
#import "OnboardingViewController.h"
#import "OnboardingContentViewController.h"

@interface AppDelegate ()
@property(nonatomic) BOOL shouldXmppGoOnline;
@property(nonatomic) MSWeakTimer *signInTimer;
@property(nonatomic) OnboardingContentViewController *page1;
@property(nonatomic) OnboardingContentViewController *page2;
@property(nonatomic) OnboardingContentViewController *page3;
@property(nonatomic) OnboardingViewController *onboardingViewController;
@property(nonatomic) UITabBarController *tabBarController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"didFinishLaunchingWithOptions");

    // Fabric crashlytics
    [Fabric with:@[[Crashlytics class]]];
    [Flurry startSession:kFlurryKey];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didSignInManually) name:kNotificationDidSignIn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didSignUpManually) name:kNotificationDidSignUp object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didCreateProfile) name:kNotificationDidCreateProfile object:nil];

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
    if (self.signInTimer)
    {
        [self.signInTimer invalidate];
        self.signInTimer = nil;
    }
    [[JYXmppManager sharedInstance] xmppUserLogout];
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

    JYCredential *credential = [JYCredential mine];
    if(credential.isEmpty)
    {
        return;
    }

    self.shouldXmppGoOnline = [self _isPresentingMessageViewController];

    NSInteger seconds = credential.tokenValidInSeconds;
    [self _autoSignInAfter:seconds];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"applicationWillTerminate");
    if (self.signInTimer)
    {
        [self.signInTimer invalidate];
        self.signInTimer = nil;
    }
    [[JYXmppManager sharedInstance] xmppUserLogout];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)_isPresentingMessageViewController
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

    [JYDeviceManager sharedInstance].deviceToken = token;
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
    }
    else if ([JYCredential mine].isEmpty)
    {
        [self _launchSignViewController];
    }
    else
    {
        [self _launchMainViewController];
    }
}

- (void)_introductionDidFinish
{
    // Update introduction history
    [JYDataStore sharedInstance].presentedIntroductionVersion = kIntroductionVersion;
    [self _launchViewController];
}

- (void)_launchSignViewController
{
    UIViewController *viewController = [JYPhoneNumberViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window.rootViewController = navigationController;
}

- (void)_launchIntroductionViewController
{
    self.window.rootViewController = self.onboardingViewController;
}

- (void)_launchMainViewController
{
    [[JYLocationManager sharedInstance] start];
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

    UIViewController *vc1 = [JYPeopleViewController new];
    UINavigationController *nc1 = [[UINavigationController alloc] initWithRootViewController:vc1];

    UIViewController *vc2 = [JYMasqueradeViewController new];
    UINavigationController *nc2 = [[UINavigationController alloc] initWithRootViewController:vc2];

    UIViewController *vc3 = [JYSessionListViewController new];
    UINavigationController *nc3 = [[UINavigationController alloc] initWithRootViewController:vc3];

    UIViewController *vc4 = [JYPhoneNumberViewController new];
    UINavigationController *nc4 = [[UINavigationController alloc] initWithRootViewController:vc4];

    _tabBarController.viewControllers = @[ nc1, nc2, nc3, nc4 ];

    UITabBar *tabBar = _tabBarController.tabBar;
    UITabBarItem *tabBarItem1 = [tabBar.items objectAtIndex:0];
    UITabBarItem *tabBarItem2 = [tabBar.items objectAtIndex:1];
    UITabBarItem *tabBarItem3 = [tabBar.items objectAtIndex:2];
    UITabBarItem *tabBarItem4 = [tabBar.items objectAtIndex:3];

    tabBarItem1.selectedImage = [[UIImage imageNamed:@"people_selected"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem1.image = [[UIImage imageNamed:@"people"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem1.title = NSLocalizedString(@"Radar", nil);

    tabBarItem2.selectedImage = [[UIImage imageNamed:@"mask_selected"] imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem2.image = [[UIImage imageNamed:@"mask"] imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem2.title = NSLocalizedString(@"Masquerade", nil);

    tabBarItem3.selectedImage = [[UIImage imageNamed:@"chat_selected"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem3.image = [[UIImage imageNamed:@"chat"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem3.title = NSLocalizedString(@"Chat", nil);

    tabBarItem4.selectedImage = [[UIImage imageNamed:@"contacts_selected"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem4.image = [[UIImage imageNamed:@"contacts"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem4.title = NSLocalizedString(@"Contacts", nil);

    return _tabBarController;
}

- (void)_didSignInManually
{
    NSInteger seconds = [JYCredential mine].tokenValidInSeconds;
    [self _autoSignInAfter:seconds];
    [self _launchMainViewController];
}

- (void)_didSignUpManually
{
    NSInteger seconds = [JYCredential mine].tokenValidInSeconds;
    [self _autoSignInAfter:seconds];
}

- (void)_didCreateProfile
{
    [self _launchMainViewController];
}

- (void)_autoSignInAfter:(NSInteger)seconds
{
    if (seconds < 0)
    {
        [self _autoSignInNow];
        return;
    }

    [[JYDeviceManager sharedInstance] start];

    [self _doAutoSignInAfter:seconds];

    if (self.shouldXmppGoOnline)
    {
        [[JYXmppManager sharedInstance] xmppUserLogin:nil];
        self.shouldXmppGoOnline = NO;
    }

    [self _refreshAWSAccess];
}

- (void)_doAutoSignInAfter:(NSInteger)seconds
{
    if (self.signInTimer)
    {
        [self.signInTimer invalidate];
    }

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.signInTimer = [MSWeakTimer scheduledTimerWithTimeInterval:seconds
                                                            target:self
                                                          selector:@selector(_autoSignInNow)
                                                          userInfo:nil
                                                           repeats:NO
                                                     dispatchQueue:queue];
}

- (void)_refreshAWSAccess
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[JYAmazonClientManager sharedInstance] goActiveWithCompletionHandler:nil];
    });
}

#pragma mark - Network

- (void)_autoSignInNow
{
    if (self.signInTimer)
    {
        [self.signInTimer invalidate];
        self.signInTimer = nil;
    }

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager managerWithPassword];
    NSString *url = [NSString apiURLWithPath:@"credential/signin"];

    NSLog(@"autoSignIn start");

    __weak typeof(self) weakSelf = self;
    [manager GET:url
        parameters:nil
        success:^(AFHTTPRequestOperation *operation, id responseObject) {

            NSLog(@"Success: autoSignIn responseObject = %@", responseObject);

            [[JYCredential mine] save:responseObject];

            NSInteger seconds = [JYCredential mine].tokenValidInSeconds;
            [weakSelf _autoSignInAfter:seconds];
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: autoSignIn Error: %@", error);
            [weakSelf _doAutoSignInAfter:kSignInRetryInSeconds];
        }];
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
