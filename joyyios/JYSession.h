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
- (NSString *)text;

@property (nonatomic) NSNumber *peerId;
@property (nonatomic) NSNumber *userId;
@property (nonatomic) NSNumber *isOutgoing;
@property (nonatomic) NSNumber *timestamp;
@property (nonatomic) NSString *body;
@property (nonatomic) NSString *resource;

@end
