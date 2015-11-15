//
//  JYPost.h
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <Mantle/Mantle.h>
#import <MTLFMDBAdapter/MTLFMDBAdapter.h>

@interface JYPost : MTLModel <MTLJSONSerializing, MTLFMDBSerializing>

+ (instancetype)postWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)error;

@property(nonatomic, readonly) NSUInteger postId;
@property(nonatomic, readonly) NSUInteger ownerId;
@property(nonatomic, readonly) NSUInteger timestamp;

@property(nonatomic, readonly, copy) NSString *idString;
@property(nonatomic, readonly, copy) NSString *caption;
@property(nonatomic, readonly, copy) NSString *shortURL;
@property(nonatomic, readonly, copy) NSString *URL;

@property(nonatomic) NSMutableArray *commentList;
@property(nonatomic) BOOL isLiked;

@end
