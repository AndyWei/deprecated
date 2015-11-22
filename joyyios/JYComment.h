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
@property(nonatomic, readonly) NSNumber *commentId;
@property(nonatomic, readonly) NSNumber *ownerId;
@property(nonatomic, readonly) NSNumber *postId;
@property(nonatomic, readonly) NSNumber *replyToId;

@end
