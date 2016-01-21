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

- (void)start
{
    NSLog(@"FriendsManager started");
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSMutableDictionary *)friendDict
{
    if (!_friendDict)
    {
        NSArray *array = [[JYLocalDataManager sharedInstance] selectObjectsOfClass:JYFriend.class];
        _friendDict = [NSMutableDictionary new];
        for (JYFriend *user in array)
        {
            [self _addFriend:user];
        }

        [self _addFriend:[JYFriend myself]];
    }
    return _friendDict;
}

- (JYFriend *)friendWithId:(NSNumber *)userid
{
    return self.friendDict[userid];
}

- (JYFriend *)friendWithBareJid:(NSString *)bareJid
{
    NSArray *parts = [bareJid componentsSeparatedByString:@"@"];
    NSString *idString = parts[0];
    NSNumber *userid = [NSNumber numberWithLongLong:idString.longLongValue];

    return [self friendWithId:userid];
}

- (JYFriend *)friendWithUsername:(NSString *)username
{
    return self.friendDict[username];
}

- (void)receivedFriendList:(NSArray *)friendList
{
    for (JYFriend *user in friendList)
    {
        if (user)
        {
            if (!self.friendDict[user.userId]) // new friend
            {
                [[JYLocalDataManager sharedInstance] insertObject:user ofClass:JYFriend.class];
            }
            else
            {
                [[JYLocalDataManager sharedInstance] updateObject:user ofClass:JYFriend.class];
            }
            [self _addFriend:user];
        }
    }
}

- (void)_addFriend:(JYFriend *)user
{
    if (user)
    {
        [_friendDict setObject:user forKey:user.userId];
        [_friendDict setObject:user forKey:user.username];
    }
}

@end
