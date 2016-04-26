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

- (NSArray *)localFriendList
{
    NSArray *list = [[JYLocalDataManager sharedInstance] selectObjectsOfClass:JYFriend.class];
    return list;
}

- (NSMutableDictionary *)friendDict
{
    if (!_friendDict)
    {
        _friendDict = [NSMutableDictionary new];
        NSMutableArray *list = [[JYLocalDataManager sharedInstance] selectObjectsOfClass:JYFriend.class];
        for (JYFriend *friend in list)
        {
            [self _addFriend:friend];
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
    NSNumber *userid = [idString uint64Number];

    return [self friendWithId:userid];
}

- (JYFriend *)friendWithUsername:(NSString *)username
{
    return self.friendDict[username];
}

- (void)receivedFriendList:(NSArray *)friendList
{
    for (JYFriend *friend in friendList)
    {
        if (friend)
        {
            if (!self.friendDict[friend.userId]) // new friend
            {
                [[JYLocalDataManager sharedInstance] insertObject:friend ofClass:JYFriend.class];
            }
            else
            {
                [[JYLocalDataManager sharedInstance] updateObject:friend ofClass:JYFriend.class];
            }
            [self _addFriend:friend];
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
