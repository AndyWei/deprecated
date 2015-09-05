//
//  JYMessage.m
//  joyyios
//
//  Created by Ping Yang on 8/25/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYMessage.h"

@interface JYMessage ()
@property(nonatomic) XMPPMessageArchiving_Message_CoreDataObject *coreDataMessage;
@property(nonatomic) JYMessageBodyType bodyType;
@end


@implementation JYMessage

#pragma mark - Initialization

- (instancetype)initWithXMPPCoreDataMessage:(XMPPMessageArchiving_Message_CoreDataObject *)coreDataMessage
{
    self = [super init];
    if (self) {
        _coreDataMessage = coreDataMessage;
    }
    return self;
}

- (JYMessageBodyType)bodyType
{
    if (_bodyType != JYMessageBodyTypeUnknown)
    {
        return _bodyType;
    }

    NSString *body = self.coreDataMessage.message.body;
    if (body == nil || [body length] == 0)
    {
        NSLog(@"Error: empty body in xmpp message = %@", self.coreDataMessage.message);
        _bodyType = JYMessageBodyTypeUnknown;
        return _bodyType;
    }

    // The body type information is stored at the beginning of "body" element
    if ([body hasPrefix:kMessageBodyTypeText])
    {
        _bodyType = JYMessageBodyTypeText;
    }
    else if ([body hasPrefix:kMessageBodyTypeImage])
    {
        _bodyType = JYMessageBodyTypeImage;
    }
    else if ([body hasPrefix:kMessageBodyTypeEmoji])
    {
        _bodyType = JYMessageBodyTypeEmoji;
    }
    else if ([body hasPrefix:kMessageBodyTypeAudio])
    {
        _bodyType = JYMessageBodyTypeAudio;
    }
    else if ([body hasPrefix:kMessageBodyTypeVideo])
    {
        _bodyType = JYMessageBodyTypeVideo;
    }
    else if ([body hasPrefix:kMessageBodyTypeLocation])
    {
        _bodyType = JYMessageBodyTypeLocation;
    }
    else if ([body hasPrefix:kMessageBodyTypeGif])
    {
        _bodyType = JYMessageBodyTypeGif;
    }

    return _bodyType;
}

- (NSString *)senderId
{
    return self.coreDataMessage.isOutgoing? self.coreDataMessage.streamBareJidStr : self.coreDataMessage.bareJidStr;
}

- (NSString *)senderDisplayName
{
    // TODO: use displayname from roster
    return self.coreDataMessage.isOutgoing? self.coreDataMessage.streamBareJidStr : self.coreDataMessage.bareJidStr;
}

- (NSDate *)date
{
    return self.coreDataMessage.timestamp;
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

- (NSUInteger)messageHash
{
    NSUInteger milliSeconds = (NSUInteger)([self.coreDataMessage.timestamp timeIntervalSinceReferenceDate] * 1000.0);
    return milliSeconds;
}

- (NSString *)text
{
    if (!_text)
    {
        _text = [self.coreDataMessage.message.body messageDisplayString];
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
            NSAssert(NO, @"Ask media for incorrect bodyType = %tu", self.bodyType);
            break;
    }

    return _media;
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
