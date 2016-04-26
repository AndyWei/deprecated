//
//  JYSession.h
//  joyyios
//
//  Created by Ping Yang on 1/30/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <Mantle/Mantle.h>
#import "MTLFMDBAdapter.h"

@interface JYSession: MTLModel <MTLFMDBSerializing>

- (instancetype)initWithXMPPMessage:(XMPPMessage *)message isOutgoing:(BOOL)isOutgoing;

@property (nonatomic) NSNumber *sessionId;
@property (nonatomic) NSNumber *userId;
@property (nonatomic) NSNumber *isGroup;

@end
