//
//  JYMessageSender.h
//  joyyios
//
//  Created by Ping Yang on 2/11/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

@interface JYMessageSender : NSObject

- (instancetype)initWithThatJID:(XMPPJID *)thatJID;

- (BOOL)sendAudioMessageWithDuration:(NSTimeInterval)duration url:(NSString *)url;
- (BOOL)sendTextMessageWithContent:(NSString *)content;
- (BOOL)sendImageMessageWithDimensions:(CGSize)dimensions url:(NSString *)url;

@end
