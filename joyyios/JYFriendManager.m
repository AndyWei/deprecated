//
//  JYFriendManager.m
//  joyyios
//
//  Created by Ping Yang on 11/29/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYFriend.h"
#import "JYFriendManager.h"
#import "JYLocalDataManager.h"

@interface JYFriendManager ()
@property (nonatomic) NSMutableDictionary *friendDict;
@end


@implementation JYFriendManager

+ (JYFriendManager *)sharedInstance
{
    static JYFriendManager *_sharedInstance = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedInstance = [JYFriendManager new];
    });

    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_apiTokenReady) name:kNotificationAPITokenReady object:nil];

        NSLog(@"FriendsManager created");
    }
    return self;
}

- (void)start
{
    NSLog(@"FriendsManager started");
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_apiTokenReady
{
    [self _fetchFriends];
}

- (NSMutableDictionary *)friendDict
{
    if (!_friendDict)
    {
        NSArray *array = [[JYLocalDataManager sharedInstance] selectFriends];
        _friendDict = [NSMutableDictionary new];
        for (JYUser *friend in array)
        {
            NSNumber *userid = friend.userId;
            [_friendDict setObject:friend forKey:userid];
        }
    }
    return _friendDict;
}

- (JYFriend *)friendOfId:(NSNumber *)userid
{
    return self.friendDict[userid];
}

- (JYFriend *)friendOfBareJid:(NSString *)bareJid
{
    NSArray *parts = [bareJid componentsSeparatedByString:@"@"];
    NSString *idString = parts[0];
    NSNumber *userid = [NSNumber numberWithLongLong:idString.longLongValue];

    return [self friendOfId:userid];
}

- (void)_fetchFriends
{
    NSString *url = [NSString apiURLWithPath:@"friends"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    [manager GET:url
       parameters:nil
          success:^(NSURLSessionTask *operation, id responseObject) {
              NSLog(@"GET friends Success");

              for (NSDictionary *dict in responseObject)
              {
                  NSError *error = nil;
                  JYFriend *friend = (JYFriend *)[MTLJSONAdapter modelOfClass:JYFriend.class fromJSONDictionary:dict error:&error];
                  if (friend)
                  {
                      if (self.friendDict[friend.userId] == nil) // new friend
                      {
                          [[JYLocalDataManager sharedInstance] insertObject:friend ofClass:JYFriend.class];
                      }
                      else
                      {
                          [[JYLocalDataManager sharedInstance] updateObject:friend ofClass:JYFriend.class];
                      }
                      [self.friendDict setObject:friend forKey:friend.userId];
                  }
              }
          }
          failure:^(NSURLSessionTask *operation, NSError *error) {
              NSLog(@"GET friends error: %@", error);
          }];
}

@end
