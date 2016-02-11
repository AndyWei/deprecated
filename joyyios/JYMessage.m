//
//  JYMessage.m
//  joyyios
//
//  Created by Ping Yang on 8/25/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFilename.h"
#import "JYImageMediaItem.h"
#import "JYMessage.h"

@interface JYMessage ()
@property (nonatomic) NSString *type;
@property (nonatomic) NSDictionary *bodyDictionary;
@property (nonatomic) CGSize dimensions;
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
             @"URL": [NSNull null],
             @"bodyDictionary": [NSNull null],
             @"bodyType": [NSNull null],
             @"dimensions": [NSNull null],
             @"media": [NSNull null],
             @"mediaUnderneath": [NSNull null],
             @"progressView": [NSNull null],
             @"resource": [NSNull null],
             @"text": [NSNull null],
             @"timestamp": [NSNull null],
             @"type": [NSNull null],
             @"uploadStatus": [NSNull null]
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
        _userId = [JYCredential current].userId;
        _body = message.body;
        _isOutgoing = [NSNumber numberWithBool:isOutgoing];
        _isUnread = [NSNumber numberWithBool:!isOutgoing];
        _uploadStatus = JYMessageUploadStatusNone;
        _peerId = isOutgoing? [message.to.bare uint64Number]:[message.from.bare uint64Number];
        _dimensions = CGSizeZero;
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    if (self = [super init])
    {
        uint64_t timestamp = (uint64_t)([NSDate timeIntervalSinceReferenceDate] * 1000000);
        _messageId = [NSNumber numberWithUnsignedLongLong:timestamp];

        _userId = [JYCredential current].userId;
        _body = @"image";
        _isOutgoing = [NSNumber numberWithBool:YES];
        _isUnread = [NSNumber numberWithBool:NO];
        _uploadStatus = JYMessageUploadStatusNone;
        _bodyType = JYMessageBodyTypeImage;
        _mediaUnderneath = image;
        _dimensions = image.size;
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
        _bodyType = JYMessageBodyTypeText;
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
    NSNumber *sender = [self.isOutgoing boolValue]? self.userId: self.peerId;
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
    return (self.bodyType == JYMessageBodyTypeImage || self.bodyType == JYMessageBodyTypeVideo || self.bodyType == JYMessageBodyTypeLocation);
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

- (NSDate *)timestamp
{
    if (!_timestamp)
    {
        uint64_t seconds = [self.messageId unsignedLongLongValue] / 1000000;
        _timestamp = [NSDate dateWithTimeIntervalSinceReferenceDate:seconds];
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

- (NSString *)URL
{
    if (self.bodyType == JYMessageBodyTypeText)
    {
        return nil;
    }

    if (!_URL)
    {
        NSArray *array = [self.resource componentsSeparatedByString:@":"];

        if ([array count] != 2)
        {
            NSLog(@"Illegal resource: %@", self.resource);
            return nil;
        }

        NSString *region = array[0];
        NSString *prefix = [[JYFilename sharedInstance] messageURLPrefixOfRegion:region];
        NSString *filename = array[1];
        _URL = [prefix stringByAppendingString:filename];
    }
    return _URL;
}

- (M13ProgressViewPie *)progressView
{
    if (![self isMediaMessage])
    {
        return nil;
    }

    if (!_progressView)
    {
        CGFloat x = CGRectGetMidX(self.media.mediaView.frame);
        CGFloat y = CGRectGetMidY(self.media.mediaView.frame);
        CGRect frame = CGRectMake(x-25, y-25, 50, 50);

        _progressView = [[M13ProgressViewPie alloc] initWithFrame:frame];
        _progressView.primaryColor = JoyyBlue;
        _progressView.secondaryColor = JoyyBlue;

        [self.media.mediaView addSubview:_progressView];
    }
    return _progressView;
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

- (CGSize)dimensions
{
    if (_dimensions.width > 0 && _dimensions.height > 0)
    {
        return _dimensions;
    }

    if ([self.bodyDictionary objectForKey:@"w"] && [self.bodyDictionary objectForKey:@"h"])
    {
        NSInteger width = [[self.bodyDictionary objectForKey:@"w"] integerValue];
        NSInteger height = [[self.bodyDictionary objectForKey:@"h"] integerValue];

        return CGSizeMake(width, height);
    }

    return CGSizeMake(kMessageMediaWidthDefault, kMessageMediaHeightDefault);
}

#pragma mark - Private methods

- (JSQMediaItem *)_imageMediaItem
{
    JYImageMediaItem *item = nil;

    // local image
    if (self.mediaUnderneath)
    {
        item = [[JYImageMediaItem alloc] initWithImage:self.mediaUnderneath];
        item.appliesMediaViewMaskAsOutgoing = YES;
    }
    else
    {
        item = [[JYImageMediaItem alloc] initWithURL:self.URL];
        item.appliesMediaViewMaskAsOutgoing = [self.isOutgoing boolValue];
    }

    item.imageDimensions = self.dimensions;
    return item;
}

- (JSQMediaItem *)_videoMediaItem
{
    // TODO: get video data from message and generate fileURL
    NSURL *fileURL = nil;
    JSQVideoMediaItem *mediaItem = [[JSQVideoMediaItem alloc] initWithFileURL:fileURL isReadyToPlay:NO];
    return mediaItem;
}

- (JSQMediaItem *)_locationMediaItem
{
    // TODO: get location data from message
    CLLocation *location = nil;
    JSQLocationMediaItem *mediaItem = [[JSQLocationMediaItem alloc] initWithLocation:location];
    return mediaItem;
}

@end
