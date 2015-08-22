//
//  JYPost.h
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

typedef NS_ENUM(NSUInteger, JYPostType)
{
    JYPostTypeImage = 0,
    JYPostTypeGif   = 1,
    JYPostTypeVideo = 2
};

@interface JYPost : NSObject

+ (NSString *)newFilename;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithLocalImage:(UIImage *)image;

@property(nonatomic) BOOL isLiked;
@property(nonatomic) JYPostType type;
@property(nonatomic) NSUInteger commentCount;
@property(nonatomic) NSUInteger likeCount;
@property(nonatomic) NSUInteger ownerId;
@property(nonatomic) NSUInteger postId;
@property(nonatomic) NSUInteger timestamp;
@property(nonatomic) NSUInteger urlVersion;
@property(nonatomic) UIImage *localImage;
@property(nonatomic, copy) NSString *filename;
@property(nonatomic, copy) NSString *caption;
@property(nonatomic, readonly) NSString *url;
@property(nonatomic, readonly) NSString *idString;
@property(nonatomic) NSMutableArray *commentList;

@end
