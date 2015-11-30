//
//  JYFriendsManager.h
//  joyyios
//
//  Created by Ping Yang on 11/29/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@interface JYFriendsManager : NSObject

+ (JYFriendsManager *)sharedInstance;

- (void)start;
- (JYUser *)userOfId:(NSNumber *)userid;
- (JYUser *)userOfBareJid:(NSString *)bareJid;

@end
