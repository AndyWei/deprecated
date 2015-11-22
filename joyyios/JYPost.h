//
//  JYPost.h
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <Mantle/Mantle.h>
#import "MTLFMDBAdapter.h"

@interface JYPost : MTLModel <MTLJSONSerializing, MTLFMDBSerializing>

@property(nonatomic, readonly) NSNumber *postId;
@property(nonatomic, readonly) NSNumber *ownerId;
@property(nonatomic, readonly) uint64_t timestamp;

@property(nonatomic, readonly, copy) NSString *caption;
@property(nonatomic, readonly, copy) NSString *shortURL;
@property(nonatomic, readonly, copy) NSString *URL;

@property(nonatomic) NSMutableArray *commentList;
@property(nonatomic) BOOL isLiked;

@end
