//
//  JYMessage.m
//  joyyios
//
//  Created by Ping Yang on 8/25/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYMessage.h"
#import "NSNumber+Joyy.h"

@interface JYMessage ()
@end


@implementation JYMessage

#pragma mark - MTLFMDBSerializing methods

+ (NSDictionary *)FMDBColumnsByPropertyKey
{
    return @{
             @"messageId": @"id",
             @"userId": @"userid",
             @"peerId": @"peerid",
             @"isOutgoing": @"isoutgoing",
             @"subject": @"subject",
             @"body": @"body",
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
        uint64_t timestamp = (uint64_t)([NSDate timeIntervalSinceReferenceDate] * 1000000);
        self.messageId = [NSNumber numberWithUnsignedLongLong:timestamp];
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
    uint64_t timestamp = [self.messageId unsignedLongLongValue] / 1000000;
    return (NSUInteger)timestamp;
}

- (NSString *)text
{
    if (!_text)
    {
        _text = self.body;
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
