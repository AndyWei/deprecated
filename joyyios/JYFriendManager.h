//
//  JYFriendManager.h
//  joyyios
//
//  Created by Ping Yang on 11/29/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@interface JYFriendManager : NSObject

+ (JYFriendManager *)sharedInstance;

- (void)start;
- (void)receivedFriendList:(NSArray *)friendList;
- (JYFriend *)friendWithId:(NSNumber *)userid;
- (JYFriend *)friendWithBareJid:(NSString *)bareJid;
- (JYFriend *)friendWithUsername:(NSString *)username;
- (NSArray *)localFriendList;

@end
