//
//  JYMessageSender.m
//  joyyios
//
//  Created by Ping Yang on 2/11/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "JYMessage.h"
#import "JYMessageSender.h"
#import "JYXmppManager.h"

@interface JYMessageSender ()
@property (nonatomic) XMPPJID *thatJID;
@end

@implementation JYMessageSender

- (instancetype)initWithThatJID:(XMPPJID *)thatJID
{
    if (self = [super init])
    {
        self.thatJID = thatJID;
    }
    return self;
}

- (BOOL)sendText:(NSString *)text
{
    return [self _sendMessageWithType:kMessageBodyTypeText resource:text dimensions:CGSizeZero alert:text];
}

- (BOOL)sendImageWithDimensions:(CGSize)dimensions URL:(NSString *)url
{
    NSString *alert = NSLocalizedString(@"send you a photo", nil);
    return [self _sendMessageWithType:kMessageBodyTypeImage resource:url dimensions:dimensions alert:alert];
}

- (BOOL)_sendMessageWithType:(NSString *)type resource:(NSString *)resource dimensions:(CGSize)dimensions alert:(NSString *)alert
{
    if (![[JYXmppManager sharedInstance].xmppStream isConnected])
    {
        return NO;
    }

    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:self.thatJID];
    NSMutableDictionary *dict = [NSMutableDictionary new];

    [dict setObject:type forKey:@"type"];
    [dict setObject:resource forKey:@"res"];

    // title is for push notification
    NSString *title = [NSString stringWithFormat:@"%@: %@", [JYCredential current].username, alert];
    [dict setObject:title forKey:@"title"];

    // ts will be used as messageId on the receiver side
    uint64_t timestamp = (uint64_t)([NSDate timeIntervalSinceReferenceDate] * 1000000);
    [dict setObject:@(timestamp) forKey:@"ts"];

    // size field is for media messages
    int64_t width = (int64_t)dimensions.width;
    int64_t height = (int64_t)dimensions.height;
    if (width > 0 && height > 0)
    {
        [dict setObject:@(width) forKey:@"w"];
        [dict setObject:@(height) forKey:@"h"];
    }

    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&err];

    if (err || !jsonData)
    {
        NSLog(@"Got an error: %@", err);
        return NO;
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [message addBody:jsonString];

    [[JYXmppManager sharedInstance].xmppStream sendElement:message];
    return YES;
}

@end
