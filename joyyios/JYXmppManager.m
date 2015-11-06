//
//  JYXmppManager.m
//  joyyios
//
//  Created by Ping Yang on 8/26/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "JYSoundPlayer.h"
#import "JYXmppManager.h"

@interface JYXmppManager() <XMPPStreamDelegate>
@property(nonatomic) BOOL apiTokenReady;
@property(nonatomic) JYXmppStatus xmppStatus;
@property(nonatomic) XMPPReconnect *reconnect;
@property(nonatomic, copy) JYXmppStatusHandler statusHandler;
@property(nonatomic, readonly)XMPPMessageArchiving *msgArchiving;
@property(nonatomic, readonly)XMPPMessageArchivingCoreDataStorage *msgStorage;
//@property (nonatomic, readonly)XMPPRoster *roster;
//@property (nonatomic, readonly)XMPPRosterCoreDataStorage *rosterStorage;
//@property (nonatomic, readonly)XMPPvCardTempModule *vCard;
//@property(nonatomic) XMPPvCardCoreDataStorage *vCardStorage;
//@property(nonatomic) XMPPvCardAvatarModule *avatar;

- (void)setupStream;
- (void)destoyStream;
- (void)connect;
- (void)authenticate;
- (void)goOnline;
- (void)goOffline;
@end


@implementation JYXmppManager

+ (instancetype)sharedInstance
{
    static JYXmppManager *_sharedInstance = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedInstance = [JYXmppManager new];
    });

    return _sharedInstance;
}

+ (XMPPJID *)jidWithUsername:(NSString *)username
{
    return [XMPPJID jidWithUser:username domain:kMessageDomain resource:nil];
}

+ (XMPPJID *)myJID
{
    // XMPP needs a "resource" string to identify different devices of the same user
    NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];

    // The first 3 chars of device ID should be enough
    NSString *prefix = [deviceId substringToIndex:3];
    NSString *resource = [NSString stringWithFormat:@"%@_%@", kMessageResource, prefix];

    return [XMPPJID jidWithUser:[JYCredential current].username domain:kMessageDomain resource:resource];
}

+ (NSFetchedResultsController *)fetcherOfSessions
{
    // Standard process for fetch XMPPMessageArchiving_Contact_CoreDataObject objects
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageArchiving_Contact_CoreDataObject"];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"mostRecentMessageTimestamp" ascending:NO];
    request.sortDescriptors = @[sort];
    request.fetchBatchSize = 10;

    // Select the messages between me and the peer
    XMPPJID *myJID = [JYXmppManager myJID];
    request.predicate = [NSPredicate predicateWithFormat:@"streamBareJidStr = %@", myJID.bare];

    NSManagedObjectContext *context = [JYXmppManager sharedInstance].msgStorage.mainThreadManagedObjectContext;

    // NOTE: DO NOT USE cache here, otherwise the messages would be disordered since XMPPFramework is writing to the same context
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];

    return controller;
}

+ (NSFetchedResultsController *)fetcherForRemoteJid:(XMPPJID *)remoteJid
{
    // Standard process for fetch XMPPMessageArchiving_Message_CoreDataObject objects
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageArchiving_Message_CoreDataObject"];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
    request.sortDescriptors = @[sort];
    request.fetchBatchSize = 10;

    // Select the messages between me and the peer
    XMPPJID *myJID = [JYXmppManager myJID];
    request.predicate = [NSPredicate predicateWithFormat:@"streamBareJidStr = %@ and bareJidStr = %@", myJID.bare, remoteJid.bare];

    NSManagedObjectContext *context = [JYXmppManager sharedInstance].msgStorage.mainThreadManagedObjectContext;

    // NOTE: DO NOT USE cache here, otherwise the messages would be disordered since XMPPFramework is writing to the same context
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];

    return controller;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.apiTokenReady = NO;
        [self setupStream];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_apiTokenReady) name:kNotificationAPITokenReady object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appStop) name:kNotificationAppDidStop object:nil];
    }
    return self;
}

- (void)dealloc
{
    [self destoyStream];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)start
{
    NSLog(@"XMPP Manager started");
    if (self.apiTokenReady)
    {
        [self _xmppUserLogin:nil];
    }
}

- (void)_apiTokenReady
{
    self.apiTokenReady = YES;
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate.shouldXmppGoOnline)
    {
        [self _xmppUserLogin:nil];
    }
}

- (void)_appStop
{
    [self goOffline];
}

- (void)setupStream
{
    // stream
    _xmppStream = [[XMPPStream alloc] init];

    // reconnect
    _reconnect = [[XMPPReconnect alloc] init];
    [_reconnect activate:_xmppStream];

    // message
    _msgStorage = [[XMPPMessageArchivingCoreDataStorage alloc] init];
    _msgArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:_msgStorage];
    [_msgArchiving activate:_xmppStream];

    // roster
//    _rosterStorage = [[XMPPRosterCoreDataStorage alloc]init];
//    _roster = [[XMPPRoster alloc]initWithRosterStorage:_rosterStorage];
//    [_roster activate:_xmppStream];

//    // vCard
//    _vCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
//    _vCard = [[XMPPvCardTempModule alloc] initWithvCardStorage:_vCardStorage];
//    [_vCard activate:_xmppStream];
//
//    // avatar
//    _avatar = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_vCard];
//    [_avatar activate:_xmppStream];
//

    // delegage
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

- (void)connect
{
    if (!_xmppStream)
    {
        [self setupStream];
    }

    _xmppStream.myJID = [[self class] myJID];
    _xmppStream.hostName = kMessageDomain;
    _xmppStream.hostPort = kMessagePort;

    NSError *error = nil;
    BOOL success = [_xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error];

    if (!success)
    {
        NSLog(@"Failure: JYXmppManager connect returned an error = %@", error);
    }
}

- (void)destoyStream
{
    [_xmppStream removeDelegate:self];
    [_reconnect deactivate];
    [_msgArchiving deactivate];
    [_xmppStream disconnect];
//    [_roster deactivate];
//    [_vCard deactivate];
//    [_avatar deactivate];

    _reconnect = nil;
    _msgArchiving = nil;
    _msgStorage = nil;
    _xmppStream = nil;

//    _roster = nil;
//    _rosterStorage = nil;
//    _vCard = nil;
//    _avatar = nil;
//    _vCardStorage = nil;
}

// Authenticate should be called after connect success
- (void)authenticate
{
    NSString *password = [JYCredential current].token;
    XMPPPlainAuthentication *auth = [[XMPPPlainAuthentication alloc] initWithStream:self.xmppStream password:password];

    // Invoke the async auth method
    NSError *error = nil;
    BOOL success = [self.xmppStream authenticate:auth error:&error];
    if (!success)
    {
        NSLog(@"Failure: xmpp authenticate failed with error = %@", error);
    }
}

// Send presence after authentication success
- (void)goOnline
{
    NSLog(@"Status: xmpp went online");
    XMPPPresence *presence = [XMPPPresence presence];
    [self.xmppStream sendElement:presence];
}

- (void)goOffline
{
    NSLog(@"Status: xmpp went offline");
    XMPPPresence *p = [XMPPPresence presenceWithType:@"unavailable"];
    [self.xmppStream sendElement:p];
}

#pragma mark - XMPPStream delegate methods
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    NSLog(@"Success: xmpp connect");

    [self authenticate];
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    NSLog(@"Failure: xmpp disconnected with error = %@", error);

    if (self.statusHandler)
    {
        self.statusHandler(JYXmppStatusNetErr, error);
    }

    // Do nothing, reconnect module will handle this.
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    NSLog(@"Success: xmpp authenticate");
    [self goOnline];

    if (self.statusHandler)
    {
        self.statusHandler(JYXmppStatusLoginSuccess, nil);
    }
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error
{
    NSLog(@"Failure: xmpp authenticate failed with error = %@", error);
    if (self.statusHandler)
    {
        self.statusHandler(JYXmppStatusLoginFailure, nil);
    }
}

- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    NSLog(@"Success: xmpp register");
    if (self.statusHandler)
    {
        self.statusHandler(JYXmppStatusRegisterSuccess, nil);
    }
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error
{

    NSLog(@"Failure: xmpp register failed with error = %@", error);
    if (self.statusHandler)
    {
        self.statusHandler(JYXmppStatusRegisterFailure, nil);
    }
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSLog(@"Success: xmpp didReceiveIQ = %@", iq);
    return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    NSLog(@"Success: xmpp didReceiveMessage = %@", message);

    // If there is a viewController to show the message, then no vibrate
    NSString *fromJid = message.from.bare;
    BOOL willShowMessage = self.currentRemoteJid && [self.currentRemoteJid.bare isEqualToString:fromJid];
    [JYSoundPlayer playMessageReceivedAlertWithVibrate:!willShowMessage];
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSLog(@"Success: xmpp didReceivePresence = %@", presence);
}

- (void)xmppStream:(XMPPStream *)sender didSendIQ:(XMPPIQ *)iq
{
    NSLog(@"Success: xmpp didSendIQ = %@", iq);
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    NSLog(@"Success: xmpp didSendMessage = %@", message);
}

- (void)xmppStream:(XMPPStream *)sender didSendPresence:(XMPPPresence *)presence
{
    NSLog(@"Success: xmpp didSendPresence = %@", presence);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendIQ:(XMPPIQ *)iq error:(NSError *)error
{
    NSLog(@"Failure: xmpp sendIQ failed with error = %@", error);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    NSLog(@"Failure: xmpp sendMessage failed with error = %@", error);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendPresence:(XMPPPresence *)presence error:(NSError *)error
{
    NSLog(@"Failure: xmpp sendPresence failed with error = %@", error);
}

- (void)_xmppUserLogin:(JYXmppStatusHandler)statusHandler
{
    self.statusHandler = statusHandler;

    // disconnect and reconnect to make sure we get a new connection
    [_xmppStream disconnect];
    [self connect];
}

@end
