//
//  JYImageMediaItem.m
//  joyyios
//
//  Created by Ping Yang on 2/8/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIKit+AFNetworking.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "JSQMessagesMediaViewBubbleImageMasker.h"
#import "JYImageMediaItem.h"

@interface JYImageMediaItem ()
@property (nonatomic) UIImageView *cachedImageView;
@end

@implementation JYImageMediaItem

#pragma mark - Initialization

- (instancetype)initWithURL:(NSString *)url
{
    self = [super init];
    if (self)
    {
        _url = [url copy];
        _image = nil;
        _cachedImageView = nil;
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self)
    {
        _url = nil;
        _image = image;
        _cachedImageView = nil;
    }
    return self;
}

- (void)dealloc
{
    _url = nil;
    _image = nil;
    _cachedImageView = nil;
}

- (void)clearCachedMediaViews
{
    [super clearCachedMediaViews];
}

#pragma mark - Setters

- (void)setAppliesMediaViewMaskAsOutgoing:(BOOL)appliesMediaViewMaskAsOutgoing
{
    [super setAppliesMediaViewMaskAsOutgoing:appliesMediaViewMaskAsOutgoing];
}

#pragma mark - Network

- (void)fetchImage
{
    __weak typeof(self) weakSelf = self;

    [self.cachedImageView sd_setImageWithURL:[NSURL URLWithString:self.url] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {

        weakSelf.image = image;
        weakSelf.cachedImageView.image = image;
    }];
}

- (void)fetchImageWithCompletion:(CompletionHandler)handler
{
    __weak typeof(self) weakSelf = self;

    [self.cachedImageView sd_setImageWithURL:[NSURL URLWithString:self.url] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {

        weakSelf.image = image;
        weakSelf.cachedImageView.image = image;

        if (handler)
        {
            handler();
        }
    }];
}

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView
{
    if (self.image)
    {
        return self.cachedImageView;
    }

    if (!self.url)
    {
        return nil;
    }

    return self.cachedImageView;
}

- (UIImageView *)cachedImageView
{
    if (!_cachedImageView)
    {
        CGSize size = [self mediaViewDisplaySize];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:_image];
        imageView.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:imageView isOutgoing:self.appliesMediaViewMaskAsOutgoing];
        _cachedImageView = imageView;
    }
    return _cachedImageView;
}

- (CGSize)mediaViewDisplaySize
{
    CGFloat min = fmin(kMessageMediaWidthDefault, kMessageMediaHeightDefault);
    CGFloat max = fmax(kMessageMediaWidthDefault, kMessageMediaHeightDefault);
    if (self.imageDimensions.width < self.imageDimensions.height)
    {
        return CGSizeMake(min, max);
    }

    return CGSizeMake(max, min);
}

- (NSUInteger)mediaHash
{
    return self.hash;
}

#pragma mark - NSObject

- (NSUInteger)hash
{
    if (self.url)
    {
         return self.url.hash;
    }
    return self.image.hash;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: url=%@, appliesMediaViewMaskAsOutgoing=%@>",
            [self class], self.url, @(self.appliesMediaViewMaskAsOutgoing)];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _url = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(url))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.url forKey:NSStringFromSelector(@selector(url))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    JYImageMediaItem *copy = [[JYImageMediaItem allocWithZone:zone] initWithURL:self.url];
    copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing;
    return copy;
}

@end

