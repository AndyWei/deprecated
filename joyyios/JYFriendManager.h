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
- (JYFriend *)friendWithId:(NSNumber *)userid;
- (JYFriend *)friendWithBareJid:(NSString *)bareJid;
- (JYFriend *)friendWithUsername:(NSString *)username;

@end
