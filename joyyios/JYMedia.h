//
//  JYMedia.h
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

typedef NS_ENUM(NSUInteger, JYMediaType)
{
    JYMediaTypeImage = 0,
    JYMediaTypeVideo = 1,
    JYMediaTypeAudio = 2
};

@interface JYMedia : NSObject

+ (NSString *)newFilename;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithLocalImage:(UIImage *)image;

@property(nonatomic) BOOL isLiked;
@property(nonatomic) JYMediaType type;
@property(nonatomic) NSUInteger mediaId;
@property(nonatomic) NSUInteger ownerId;
@property(nonatomic) NSUInteger urlVersion;
@property(nonatomic) NSUInteger timestamp;
@property(nonatomic) UIImage *localImage;
@property(nonatomic, copy) NSString *filename;
@property(nonatomic, copy) NSString *caption;
@property(nonatomic, readonly) NSString *url;

// Brief related
- (void)setBrief:(NSDictionary *)brief;
@property(nonatomic) NSUInteger likeCount;
@property(nonatomic) NSUInteger commentCount;
@property(nonatomic) NSArray *commentList;

@end
