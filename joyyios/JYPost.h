//
//  JYPost.h
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@interface JYPost : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@property(nonatomic) BOOL isLiked;
@property(nonatomic) NSUInteger commentCount;
@property(nonatomic) NSUInteger likeCount;
@property(nonatomic) NSUInteger ownerId;
@property(nonatomic) NSUInteger postId;
@property(nonatomic) NSUInteger timestamp;
@property(nonatomic) UIImage *localImage;
@property(nonatomic) NSString *filename;
@property(nonatomic) NSString *caption;
@property(nonatomic, readonly) NSString *url;
@property(nonatomic, readonly) NSString *idString;
@property(nonatomic) NSMutableArray *commentList;

@end
