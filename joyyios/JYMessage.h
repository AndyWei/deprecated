//
//  JYMessage.h
//  joyyios
//
//  This is a concrete class of JSQMessageData protocol that represents a single user message.
//
//  Created by Ping Yang on 8/25/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <JSQMessagesViewController/JSQMessages.h>
#import <Mantle/Mantle.h>
#import "MTLFMDBAdapter.h"

typedef NS_ENUM(NSUInteger, JYMessageBodyType)
{
    JYMessageBodyTypeUnknown  = 0,
    JYMessageBodyTypeAudio    = 1,
    JYMessageBodyTypeEmoji    = 2,
    JYMessageBodyTypeGif      = 3,
    JYMessageBodyTypeImage    = 4,
    JYMessageBodyTypeLocation = 5,
    JYMessageBodyTypeText     = 6,
    JYMessageBodyTypeVideo    = 7
};

@interface JYMessage: MTLModel <JSQMessageData, MTLFMDBSerializing>

- (instancetype)initWithXMPPMessage:(XMPPMessage *)message isOutgoing:(BOOL)isOutgoing;
- (BOOL)isTextMessage;
- (BOOL)hasGapWith:(JYMessage *)that;

// FMDB coloumns
@property (nonatomic) NSNumber *messageId;
@property (nonatomic) NSNumber *userId;
@property (nonatomic) NSNumber *peerId;
@property (nonatomic) NSNumber *isOutgoing;
@property (nonatomic) NSString *body;

// non FMDB coloumns
@property (nonatomic) JYMessageBodyType bodyType;
@property (nonatomic) NSString *resource;
@property (nonatomic) NSDate *timestamp;
@property (nonatomic) NSString *text;
@property (nonatomic) id<JSQMessageMediaData> media;

@end
