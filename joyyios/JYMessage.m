//
//  JYMessage.m
//  joyyios
//
//  Created by Ping Yang on 8/25/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYMessage.h"

@interface JYMessage ()
@property (nonatomic) NSString *type;
@property (nonatomic) NSDictionary *bodyDictionary;
@end


@implementation JYMessage

#pragma mark - MTLFMDBSerializing methods

+ (NSDictionary *)FMDBColumnsByPropertyKey
{
    return @{
             @"messageId": @"id",
             @"userId": @"user_id",
             @"peerId": @"peer_id",
             @"isOutgoing": @"is_outgoing",
             @"isUnread": @"is_unread",
             @"body": @"body",
             @"bodyDictionary": [NSNull null],
             @"type": [NSNull null],
             @"resource": [NSNull null],
             @"bodyType": [NSNull null],
             @"text": [NSNull null],
             @"media": [NSNull null],
             @"timestamp": [NSNull null]
             };
}

+ (NSArray *)FMDBPrimaryKeys
{
    return @[@"id"];
}

+ (NSString *)FMDBTableName
{
    return @"message";
}

#pragma mark - Initialization

- (instancetype)initWithXMPPMessage:(XMPPMessage *)message isOutgoing:(BOOL)isOutgoing
{
    if (self = [super init])
    {
        self.userId = [JYCredential current].userId;
        self.body = message.body;
        self.isOutgoing = [NSNumber numberWithBool:isOutgoing];
        self.isUnread = [NSNumber numberWithBool:!isOutgoing];
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

- (NSNumber *)messageId
{
    if (!_messageId)
    {
        NSString *timestampStr = [self.bodyDictionary objectForKey:@"ts"];
        _messageId = [timestampStr uint64Number];
    }
    return _messageId;
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

- (NSString *)senderId
{
    NSNumber *sender = [self.isOutgoing boolValue]? self.userId : self.peerId;
    return [sender uint64String];
}

- (NSString *)senderDisplayName
{
    // TODO: use displayname from JYFriendManager
    return self.senderId;
}

- (NSDate *)date
{
    uint64_t timestamp = [self.messageId unsignedLongLongValue] / 1000000;
    return [NSDate dateWithTimeIntervalSinceReferenceDate:timestamp];
}

- (BOOL)isTextMessage
{
    return (self.bodyType == JYMessageBodyTypeText);
}

- (BOOL)isMediaMessage
{
    BOOL isMedia = (self.bodyType == JYMessageBodyTypeImage ||
                    self.bodyType == JYMessageBodyTypeVideo ||
                    self.bodyType == JYMessageBodyTypeLocation);
    return isMedia;
}

- (BOOL)hasGapWith:(JYMessage *)that
{
    NSDate *d1 = self.timestamp;
    NSDate *d2 = that.timestamp;
    NSTimeInterval gap = [d1 timeIntervalSinceDate:d2];
    return (gap > k5Minutes);
}

- (NSUInteger)messageHash
{
    uint64_t timestamp = [self.messageId unsignedLongLongValue];
    return (NSUInteger)timestamp;
}

- (NSString *)text
{
    if (!_text)
    {
        _text = self.resource;
    }

    return _text;
}

- (id<JSQMessageMediaData>)media
{
    if (_media)
    {
        return _media;
    }

    switch (self.bodyType)
    {
        case JYMessageBodyTypeImage:
            _media = [self _imageMediaItem];
            break;
        case JYMessageBodyTypeVideo:
            _media = [self _videoMediaItem];
            break;
        case JYMessageBodyTypeLocation:
            _media = [self _locationMediaItem];
            break;
        default:
            _media = nil;
            break;
    }

    return _media;
}

- (NSDate *)timestamp
{
    if (!_timestamp)
    {
        uint64_t t = [self.messageId unsignedLongLongValue] / 1000000;
        _timestamp = [NSDate dateWithTimeIntervalSinceReferenceDate:t];
    }
    return _timestamp;
}

- (NSString *)liteText
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

#pragma mark - Private methods

- (JSQPhotoMediaItem *)_imageMediaItem
{
    // TODO: get image data from message
    UIImage *image = nil;
    JSQPhotoMediaItem *mediaItem = [[JSQPhotoMediaItem alloc] initWithImage:image];
    return mediaItem;
}

- (JSQVideoMediaItem *)_videoMediaItem
{
    // TODO: get video data from message and generate fileURL
    NSURL *fileURL = nil;
    JSQVideoMediaItem *mediaItem = [[JSQVideoMediaItem alloc] initWithFileURL:fileURL isReadyToPlay:NO];
    return mediaItem;
}

- (JSQLocationMediaItem *)_locationMediaItem
{
    // TODO: get location data from message
    CLLocation *location = nil;
    JSQLocationMediaItem *mediaItem = [[JSQLocationMediaItem alloc] initWithLocation:location];
    return mediaItem;
}

@end
