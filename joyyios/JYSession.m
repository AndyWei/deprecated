//
//  JYSession.m
//  joyyios
//
//  Created by Ping Yang on 1/30/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "JYMessage.h"
#import "JYSession.h"

@interface JYSession ()
@property (nonatomic) JYMessageBodyType bodyType;
@end

@implementation JYSession

#pragma mark - MTLFMDBSerializing methods

+ (NSDictionary *)FMDBColumnsByPropertyKey
{
    return @{
             @"peerId": @"id",
             @"userId": @"userid",
             @"subject": @"subject",
             @"body": @"body",
             @"isOutgoing": @"isoutgoing",
             @"timestamp": @"timestamp",
             @"bodyType": [NSNull null]
             };
}

+ (NSArray *)FMDBPrimaryKeys
{
    return @[@"id"];
}

+ (NSString *)FMDBTableName
{
    return @"session";
}

#pragma mark - Initialization

- (instancetype)initWithXMPPMessage:(XMPPMessage *)message isOutgoing:(BOOL)isOutgoing
{
    if (self = [super init])
    {
        self.timestamp = [NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]];
        self.userId = [JYCredential current].userId;
        self.subject = message.subject;
        self.body = message.body;
        self.isOutgoing = [NSNumber numberWithBool:isOutgoing];
        self.peerId = isOutgoing? [message.to.bare uint64Number]:[message.from.bare uint64Number];
    }
    return self;
}

- (JYMessageBodyType)bodyType
{
    if (_bodyType != JYMessageBodyTypeUnknown)
    {
        return _bodyType;
    }

    NSString *subject = self.subject;
    if ([subject length] == 0)
    {
        _bodyType = JYMessageBodyTypeUnknown;
        return _bodyType;
    }

    _bodyType = JYMessageBodyTypeText;

    // The body type information is stored in the "subject" element
    if ([subject isEqualToString:kMessageBodyTypeText])
    {
        _bodyType = JYMessageBodyTypeText;
    }
    else if ([subject isEqualToString:kMessageBodyTypeImage])
    {
        _bodyType = JYMessageBodyTypeImage;
    }
    else if ([subject isEqualToString:kMessageBodyTypeEmoji])
    {
        _bodyType = JYMessageBodyTypeEmoji;
    }
    else if ([subject isEqualToString:kMessageBodyTypeAudio])
    {
        _bodyType = JYMessageBodyTypeAudio;
    }
    else if ([subject isEqualToString:kMessageBodyTypeVideo])
    {
        _bodyType = JYMessageBodyTypeVideo;
    }
    else if ([subject isEqualToString:kMessageBodyTypeLocation])
    {
        _bodyType = JYMessageBodyTypeLocation;
    }
    else if ([subject isEqualToString:kMessageBodyTypeGif])
    {
        _bodyType = JYMessageBodyTypeGif;
    }

    return _bodyType;
}

- (NSString *)text
{
    NSString *ret = nil;
    switch (self.bodyType)
    {
        case JYMessageBodyTypeText:
            ret = self.body;
            break;

        case JYMessageBodyTypeImage:
            ret = @"🌋";
            break;

        case JYMessageBodyTypeEmoji:
            ret = self.body;
            break;

        case JYMessageBodyTypeAudio:
            ret = @"🔊";
            break;

        case JYMessageBodyTypeVideo:
            ret = @"🎬";
            break;

        case JYMessageBodyTypeLocation:
            ret = @"📍";
            break;

        case JYMessageBodyTypeGif:
            ret = @"🎬";
            break;

        default:
            break;
    }
    return ret;
}

@end
