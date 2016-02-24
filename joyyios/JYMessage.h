//
//  JYMessage.h
//  joyyios
//
//  This is a concrete class of JSQMessageData protocol that represents a single user message.
//
//  Created by Ping Yang on 8/25/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <Mantle/Mantle.h>
#import "MTLFMDBAdapter.h"

typedef NS_ENUM(NSUInteger, JYMessageType)
{
    JYMessageTypeUnknown  = 0,
    JYMessageTypeAudio    = 1,
    JYMessageTypeEmoji    = 2,
    JYMessageTypeGif      = 3,
    JYMessageTypeImage    = 4,
    JYMessageTypeLocation = 5,
    JYMessageTypeText     = 6,
    JYMessageTypeVideo    = 7
};

typedef NS_ENUM(NSUInteger, JYMessageUploadStatus)
{
    JYMessageUploadStatusNone    = 0,
    JYMessageUploadStatusOngoing = 1,
    JYMessageUploadStatusSuccess = 2,
    JYMessageUploadStatusFailure = 3
};

@interface JYMessage: MTLModel <MTLFMDBSerializing>

- (instancetype)initWithXMPPMessage:(XMPPMessage *)message isOutgoing:(BOOL)isOutgoing;
- (instancetype)initWithText:(NSString *)text;
- (instancetype)initWithImage:(UIImage *)image;
- (instancetype)initWithAudioFile:(NSURL *)fileURL duration:(NSTimeInterval)duration;

- (BOOL)isTextMessage;
- (BOOL)isMediaMessage;
- (BOOL)hasGapWith:(JYMessage *)that;

- (NSString *)liteText;

// FMDB coloumns
@property (nonatomic) NSNumber *messageId;
@property (nonatomic) NSNumber *userId;
@property (nonatomic) NSNumber *peerId;
@property (nonatomic) NSNumber *isOutgoing;
@property (nonatomic) NSNumber *isUnread;
@property (nonatomic) NSString *body;

// non FMDB coloumns
@property (nonatomic) CGSize dimensions;
@property (nonatomic) CGSize displayDimensions;
@property (nonatomic) JYMessageUploadStatus uploadStatus;
@property (nonatomic) JYMessageType type;
@property (nonatomic) NSString *resource;
@property (nonatomic) NSDate *timestamp;
@property (nonatomic) NSString *text;
@property (nonatomic) NSString *url;
@property (nonatomic) id media;

@end
