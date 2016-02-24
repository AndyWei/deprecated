//
//  JYMessage.m
//  joyyios
//
//  Created by Ping Yang on 8/25/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFilename.h"
#import "JYMessage.h"

@interface JYMessage ()
@property (nonatomic) NSString *typeString;
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
             @"dimensions": [NSNull null],
             @"displayDimensions": [NSNull null],
             @"media": [NSNull null],
             @"resource": [NSNull null],
             @"text": [NSNull null],
             @"timestamp": [NSNull null],
             @"type": [NSNull null],
             @"typeString": [NSNull null],
             @"uploadStatus": [NSNull null],
             @"url": [NSNull null]
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

- (instancetype)initWithText:(NSString *)text
{
    if (self = [super init])
    {
        [self _commonInit];
        _text = text;
        _type = JYMessageTypeText;
        _dimensions = CGSizeZero;
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    if (self = [super init])
    {
        [self _commonInit];
        _body = @"image";

        _type = JYMessageTypeImage;
        _media = image;
        _dimensions = image.size;
    }
    return self;
}

- (instancetype)initWithAudioFile:(NSURL *)fileURL duration:(NSTimeInterval)duration
{
    if (self = [super init])
    {
        [self _commonInit];
        _body = @"audio";

        _type = JYMessageTypeAudio;
        _media = fileURL;
        _dimensions = CGSizeMake(duration, 35);;
    }
    return self;
}

- (void)_commonInit
{
    uint64_t timestamp = (uint64_t)([NSDate timeIntervalSinceReferenceDate] * 1000000);
    _messageId = [NSNumber numberWithUnsignedLongLong:timestamp];

    _userId = [JYCredential current].userId;
    _isOutgoing = [NSNumber numberWithBool:YES];
    _isUnread = [NSNumber numberWithBool:NO];
    _uploadStatus = JYMessageUploadStatusNone;
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

- (NSString *)typeString
{
    if (!_typeString)
    {
        _typeString = [self.bodyDictionary objectForKey:@"type"];
    }
    return _typeString;
}

- (NSString *)resource
{
    if (!_resource)
    {
        _resource = [self.bodyDictionary objectForKey:@"res"];
    }
    return _resource;
}

- (JYMessageType)type
{
    if (_type != JYMessageTypeUnknown)
    {
        return _type;
    }

    if ([self.typeString length] == 0)
    {
        _type = JYMessageTypeText;
        return _type;
    }

    _type = JYMessageTypeText;

    // The body type information is stored in the "subject" element
    if ([self.typeString isEqualToString:kMessageBodyTypeText])
    {
        _type = JYMessageTypeText;
    }
    else if ([self.typeString isEqualToString:kMessageBodyTypeImage])
    {
        _type = JYMessageTypeImage;
    }
    else if ([self.typeString isEqualToString:kMessageBodyTypeEmoji])
    {
        _type = JYMessageTypeEmoji;
    }
    else if ([self.typeString isEqualToString:kMessageBodyTypeAudio])
    {
        _type = JYMessageTypeAudio;
    }
    else if ([self.typeString isEqualToString:kMessageBodyTypeVideo])
    {
        _type = JYMessageTypeVideo;
    }
    else if ([self.typeString isEqualToString:kMessageBodyTypeLocation])
    {
        _type = JYMessageTypeLocation;
    }
    else if ([self.typeString isEqualToString:kMessageBodyTypeGif])
    {
        _type = JYMessageTypeGif;
    }

    return _type;
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

- (BOOL)isTextMessage
{
    return (self.type == JYMessageTypeText);
}

- (BOOL)isMediaMessage
{
    return ![self isTextMessage];
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

- (NSString *)liteText
{
    NSString *ret = nil;
    switch (self.type)
    {
        case JYMessageTypeText:
            ret = self.resource;
            break;

        case JYMessageTypeImage:
            ret = @"🌋";
            break;

        case JYMessageTypeEmoji:
            ret = self.body;
            break;

        case JYMessageTypeAudio:
            ret = @"🔊";
            break;

        case JYMessageTypeVideo:
            ret = @"🎬";
            break;

        case JYMessageTypeLocation:
            ret = @"📍";
            break;

        case JYMessageTypeGif:
            ret = @"🎬";
            break;
            
        default:
            break;
    }
    return ret;
}

- (NSString *)url
{
    if (self.type == JYMessageTypeText)
    {
        return nil;
    }

    if (!_url)
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
        _url = [prefix stringByAppendingString:filename];
    }
    return _url;
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

- (CGSize)displayDimensions
{
    if (self.type == JYMessageTypeAudio)
    {
        return CGSizeMake(100, 35);
    }

    CGFloat min = fmin(kMessageMediaWidthDefault, kMessageMediaHeightDefault);
    CGFloat max = fmax(kMessageMediaWidthDefault, kMessageMediaHeightDefault);
    if (self.dimensions.width < self.dimensions.height)
    {
        return CGSizeMake(min, max);
    }

    return CGSizeMake(max, min);
}

@end
