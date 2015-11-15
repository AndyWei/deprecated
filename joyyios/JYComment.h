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

+ (instancetype)commentWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)error;

@property(nonatomic, readonly, copy) NSString *content;
@property(nonatomic, readonly) NSUInteger commentId;
@property(nonatomic, readonly) NSUInteger ownerId;
@property(nonatomic, readonly) NSUInteger postId;
@property(nonatomic, readonly) NSUInteger replyToId;

@end
