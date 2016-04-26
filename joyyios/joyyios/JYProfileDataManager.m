//
//  JYProfileDataManager.m
//  joyyios
//
//  Created by Ping Yang on 1/20/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "JYFriendManager.h"
#import "JYInvite.h"
#import "JYLocalDataManager.h"
#import "JYMonth.h"
#import "JYPost.h"
#import "JYWink.h"
#import "JYProfileDataManager.h"

@interface JYProfileDataManager ()
@property (nonatomic) JYMonth *month;
@property (nonatomic) JYUser *me;
@end

@implementation JYProfileDataManager

- (instancetype)init
{
    if (self = [super init])
    {
        self.month = [[JYMonth alloc] initWithDate:[NSDate date]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_apiTokenReady) name:kNotificationAPITokenReady object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)start
{
    if ([JYCredential current].tokenValidInSeconds > 0)
    {
        self.me = [JYFriend myself];
        [self.delegate manager:self didReceiveOwnProfile:self.me];
       [self _fetchData];
    }
}

- (void)_apiTokenReady
{
    if (!self.me)
    {
        self.me = [JYFriend myself];
        [self.delegate manager:self didReceiveOwnProfile:self.me];
        [self _fetchData];
    }
}

- (void)_fetchData
{
    [self _fetchFriends];
    [self _fetchInvites];
    [self _fetchWinks];
    [self fetchUserline];
}

- (void)fetchUserline
{
    uint64_t monthValue = self.month.value;
    self.month = [self.month prev];
    [self _fetchUserlineOfMonth:monthValue];
}

- (void)_fetchUserlineOfMonth:(uint64_t)month
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    NSString *url = [NSString apiURLWithPath:@"post/userline"];
    NSDictionary *parameters = @{@"userid": [self.me.userId uint64Number], @"month": @(month)};

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
        progress:nil
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"GET post/userline fetch success responseObject: %@", responseObject);

             // the post json is in ASC order, so iterate reversely
             NSMutableArray *postList = [NSMutableArray new];
             for (NSDictionary *dict in [responseObject reverseObjectEnumerator])
             {
                 NSError *error = nil;
                 JYPost *post = (JYPost *)[MTLJSONAdapter modelOfClass:JYPost.class fromJSONDictionary:dict error:&error];
                 if (post)
                 {
                     [postList addObject:post];
                 }
             }
             [weakSelf _didReceivePosts:postList];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"Error: GET post/userline fetch failed with error: %@", error);
         }
     ];
}

- (void)_fetchFriends
{
    NSString *url = [NSString apiURLWithPath:@"friends"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:nil
        progress:nil
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"GET friends Success");

             NSMutableArray *friendList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 NSError *error = nil;
                 JYFriend *friend = (JYFriend *)[MTLJSONAdapter modelOfClass:JYFriend.class fromJSONDictionary:dict error:&error];
                 if (friend)
                 {
                     [friendList addObject:friend];
                 }
             }

             //              test only
             //                 JYUser *user = [JYFriend myself];
             //                 for (int i = 0; i < 10; ++i)
             //                 {
             //                     [friendList addObject:user];
             //                 }
             //

             [weakSelf _didReceiveFriends:friendList];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"GET friends error: %@", error);
         }];
}

- (void)_fetchInvites
{
    NSString *url = [NSString apiURLWithPath:@"invites"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:[self _fetchInvitesParameters]
        progress:nil
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"GET invites Success");
             [weakSelf _didReceiveInvites:(NSMutableArray *)responseObject];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"GET invites error: %@", error);
         }];
}

- (NSDictionary *)_fetchInvitesParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    JYInvite *maxInvite = (JYInvite *)[[JYLocalDataManager sharedInstance] maxIdObjectOfOfClass:JYInvite.class];
    if (maxInvite)
    {
        [parameters setObject:[maxInvite.inviteId uint64Number] forKey:@"sinceid"];
    }
    else
    {
        [parameters setObject:@(0) forKey:@"sinceid"];
    }

    [parameters setObject:@(LLONG_MAX) forKey:@"beforeid"];

    return parameters;
}

- (void)_fetchWinks
{
    NSString *url = [NSString apiURLWithPath:@"winks"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:[self _fetchWinksParameters]
        progress:nil
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"GET winks Success");

             NSMutableArray *winkList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject) // results are in DESC
             {
                 NSError *error = nil;
                 JYWink *wink = (JYWink *)[MTLJSONAdapter modelOfClass:JYWink.class fromJSONDictionary:dict error:&error];
                 if (wink)
                 {
                     [[JYLocalDataManager sharedInstance] insertObject:wink ofClass:JYWink.class];
                     [winkList addObject:wink];
                 }
             }
             [weakSelf _didReceiveWinks:winkList];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"GET winks error: %@", error);
         }];
}

- (NSDictionary *)_fetchWinksParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    JYWink *maxWink = (JYWink *)[[JYLocalDataManager sharedInstance] maxIdObjectOfOfClass:JYWink.class];
    if (maxWink)
    {
        [parameters setObject:[maxWink.winkId uint64Number] forKey:@"sinceid"];
    }
    else
    {
        [parameters setObject:@(0) forKey:@"sinceid"];
    }
    
    [parameters setObject:@(LLONG_MAX) forKey:@"beforeid"];
    
    return parameters;
}

- (void)_didReceivePosts:(NSMutableArray *)list
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.delegate manager:self didReceivePosts:list];
    });
}

- (void)_didReceiveFriends:(NSMutableArray *)list
{
    [[JYFriendManager sharedInstance] receivedFriendList:list];
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.delegate manager:self didReceiveFriends:list];
    });
}

- (void)_didReceiveInvites:(NSMutableArray *)list
{
    NSMutableArray *inviteList = [NSMutableArray new];
    for (NSDictionary *dict in list)
    {
        NSError *error = nil;
        JYInvite *invite = (JYInvite *)[MTLJSONAdapter modelOfClass:JYInvite.class fromJSONDictionary:dict error:&error];
        if (invite)
        {
            [[JYLocalDataManager sharedInstance] insertObject:invite ofClass:JYInvite.class];
            [inviteList addObject:invite];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.delegate manager:self didReceiveInvites:inviteList];
    });
}

- (void)_didReceiveWinks:(NSMutableArray *)list
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.delegate manager:self didReceiveWinks:list];
    });
}

@end
