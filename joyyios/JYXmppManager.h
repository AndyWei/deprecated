//
//  JYXmppManager.h
//  joyyios 
//
//  Created by Ping Yang on 8/26/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef NS_ENUM(NSUInteger, JYXmppStatus)
{
    JYXmppStatusLoginSuccess,
    JYXmppStatusLoginFailure,
    JYXmppStatusNetErr,
    JYXmppStatusRegisterSuccess,
    JYXmppStatusRegisterFailure
};

typedef void(^JYXmppStatusHandler)(JYXmppStatus type, NSError *error);

@interface JYXmppManager : NSObject

+ (JYXmppManager *)sharedInstance;
+ (NSFetchedResultsController *)fetcherOfSessions;
+ (NSFetchedResultsController *)fetcherForRemoteJid:(XMPPJID *)remoteJid;
+ (XMPPJID *)jidWithUsername:(NSString *)username;
+ (XMPPJID *)myJID;
- (void)start;

@property(nonatomic) XMPPJID *currentRemoteJid;
@property(nonatomic, readonly) XMPPStream *xmppStream;

@end
