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

@interface JYMessage : NSObject <JSQMessageData>

- (instancetype)initWithXMPPCoreDataMessage:(XMPPMessageArchiving_Message_CoreDataObject *)coreDataMessage;
- (BOOL)isTextMessage;

@property (nonatomic) NSString *text;
@property (nonatomic) id<JSQMessageMediaData> media;

@end
