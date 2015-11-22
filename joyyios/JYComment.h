//
//  JYComment.h
//  joyyios
//
//  Created by Ping Yang on 5/24/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <Mantle/Mantle.h>
#import "MTLFMDBAdapter.h"

@interface JYComment : MTLModel <MTLJSONSerializing, MTLFMDBSerializing>

@property(nonatomic, readonly, copy) NSString *content;
@property(nonatomic, readonly, copy) NSString *displayText;
@property(nonatomic, readonly) uint64_t commentId;
@property(nonatomic, readonly) uint64_t ownerId;
@property(nonatomic, readonly) uint64_t postId;
@property(nonatomic, readonly) uint64_t replyToId;

@end
