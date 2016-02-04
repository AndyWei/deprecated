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
@property (nonatomic) NSDictionary *bodyDictionary;
@property (nonatomic) NSString *type;
@end

@implementation JYSession

#pragma mark - MTLFMDBSerializing methods

+ (NSDictionary *)FMDBColumnsByPropertyKey
{
    return @{
             @"peerId": @"id",
             @"userId": @"userid",
             @"body": @"body",
             @"isOutgoing": @"isoutgoing",
             @"hasRead": @"hasread",
             @"timestamp": @"timestamp",
             @"bodyDictionary": [NSNull null],
             @"type": [NSNull null],
             @"resource": [NSNull null],
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
        self.body = message.body;
        self.isOutgoing = [NSNumber numberWithBool:isOutgoing];
        self.hasRead = [NSNumber numberWithBool:isOutgoing]; // mark all incoming ones as unread
        self.peerId = isOutgoing? [message.to.bare uint64Number]:[message.from.bare uint64Number];
    }
    return self;
}

- (NSDictionary *)bodyDictionary
{
    if (!_bodyDictionary)
    {
        NSError *error;
        NSData *objectData = [self.body dataUsingEncoding:NSUTF8StringEncoding];
        _bodyDictionary = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers error:&error];
    }
    return _bodyDictionary;
}

- (NSString *)type
{
    if (!_type)
    {
        _type = [self.bodyDictionary objectForKey:@"type"];
    }
    return _type;
}

- (NSString *)resource
{
    if (!_resource)
    {
        _resource = [self.bodyDictionary objectForKey:@"res"];
    }
    return _resource;
}

- (JYMessageBodyType)bodyType
{
    if (_bodyType != JYMessageBodyTypeUnknown)
    {
        return _bodyType;
    }


    if ([self.type length] == 0)
    {
        _bodyType = JYMessageBodyTypeUnknown;
        return _bodyType;
    }

    _bodyType = JYMessageBodyTypeText;

    // The body type information is stored in the "subject" element
    if ([self.type isEqualToString:kMessageBodyTypeText])
    {
        _bodyType = JYMessageBodyTypeText;
    }
    else if ([self.type isEqualToString:kMessageBodyTypeImage])
    {
        _bodyType = JYMessageBodyTypeImage;
    }
    else if ([self.type isEqualToString:kMessageBodyTypeEmoji])
    {
        _bodyType = JYMessageBodyTypeEmoji;
    }
    else if ([self.type isEqualToString:kMessageBodyTypeAudio])
    {
        _bodyType = JYMessageBodyTypeAudio;
    }
    else if ([self.type isEqualToString:kMessageBodyTypeVideo])
    {
        _bodyType = JYMessageBodyTypeVideo;
    }
    else if ([self.type isEqualToString:kMessageBodyTypeLocation])
    {
        _bodyType = JYMessageBodyTypeLocation;
    }
    else if ([self.type isEqualToString:kMessageBodyTypeGif])
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
            ret = self.resource;
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
