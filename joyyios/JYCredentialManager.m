//
//  JYCredentialManager.m
//  joyyios
//
//  Created by Ping Yang on 11/4/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <MSWeakTimer/MSWeakTimer.h>

#import "JYCredentialManager.h"

@interface JYCredentialManager ()
@property(nonatomic) MSWeakTimer *signInTimer;
@end

@implementation JYCredentialManager

+ (JYCredentialManager *)sharedInstance
{
    static JYCredentialManager *_sharedInstance = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedInstance = [JYCredentialManager new];
    });

    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appStop) name:kNotificationAppDidStop object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)start
{
    JYCredential *credential = [JYCredential current];
    if(credential.isEmpty)
    {
        return;
    }

    NSInteger seconds = credential.tokenValidInSeconds;
    [self _autoSignInAfter:seconds];
}

- (void)_autoSignInAfter:(NSInteger)seconds
{
    if (seconds <= 0)
    {
        [self _autoSignInNow];
        return;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationAPITokenReady object:nil];

    [self _startSignInTimer:seconds];
}

- (void)_startSignInTimer:(NSInteger)seconds
{
    [self _stopAutoSignInTimer];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.signInTimer = [MSWeakTimer scheduledTimerWithTimeInterval:seconds
                                                            target:self
                                                          selector:@selector(_autoSignInNow)
                                                          userInfo:nil
                                                           repeats:NO
                                                     dispatchQueue:queue];
}

#pragma mark - Network

- (void)_autoSignInNow
{
    [self _stopAutoSignInTimer];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *url = [NSString apiURLWithPath:@"auth/signin"];
    NSString *username = [JYCredential current].username;
    NSString *password = [JYCredential current].password;

    NSDictionary *parameters = @{ @"username":username, @"password":password };
    NSLog(@"autoSignIn start");

    __weak typeof(self) weakSelf = self;
    [manager POST:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {

             NSLog(@"Success: autoSignIn responseObject = %@", responseObject);

             [[JYCredential current] save:responseObject];

             NSInteger seconds = [JYCredential current].tokenValidInSeconds;
             [weakSelf _autoSignInAfter:seconds];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"Error: autoSignIn Error: %@", error);
             [weakSelf _startSignInTimer:kSignInRetryInSeconds];
         }];
}

- (void)_stopAutoSignInTimer
{
    if (self.signInTimer)
    {
        [self.signInTimer invalidate];
        self.signInTimer = nil;
    }
}

- (void)_appStop
{
    [self _stopAutoSignInTimer];
}

@end
