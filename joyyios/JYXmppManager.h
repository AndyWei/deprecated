//
//  JYXmppManager.h
//  joyyios 
//
//  Created by Ping Yang on 8/26/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "JYPerson.h"

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
+ (NSFetchedResultsController *)fetchedResultsControllerForRemoteJid:(XMPPJID *)remoteJid;
+ (XMPPJID *)jidWithUserIdString:(NSString *)idString;
+ (XMPPJID *)myJid;

- (void)xmppUserLogin:(JYXmppStatusHandler)statusBlock;
- (void)xmppUserLogout;

@property(nonatomic) XMPPJID *currentRemoteJid;
@property(nonatomic, readonly) XMPPStream *xmppStream;

@end
