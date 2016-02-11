//
//  JYMessageSender.h
//  joyyios
//
//  Created by Ping Yang on 2/11/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

@interface JYMessageSender : NSObject

- (instancetype)initWithThatJID:(XMPPJID *)thatJID;

- (BOOL)sendText:(NSString *)text;
- (BOOL)sendImageWithDimensions:(CGSize)dimensions URL:(NSString *)url;

@end
