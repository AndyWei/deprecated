//
//  JYImageMediaItem.m
//  joyyios
//
//  Created by Ping Yang on 2/8/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIKit+AFNetworking.h>

#import "JSQMessagesMediaViewBubbleImageMasker.h"
#import "JYImageMediaItem.h"

@interface JYImageMediaItem ()
@property (nonatomic) UIImageView *cachedImageView;
@property (nonatomic) BOOL hasFetchedImage;
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
        _hasFetchedImage = NO;
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
        _hasFetchedImage = NO;
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
    _image = nil;
    _cachedImageView = nil;
    _hasFetchedImage = NO;
}

#pragma mark - Setters

- (void)setUrl:(NSString *)url
{
    _url = [url copy];
    _image = nil;
    _cachedImageView = nil;
    _hasFetchedImage = NO;
}

- (void)setAppliesMediaViewMaskAsOutgoing:(BOOL)appliesMediaViewMaskAsOutgoing
{
    [super setAppliesMediaViewMaskAsOutgoing:appliesMediaViewMaskAsOutgoing];
}

#pragma mark - Network

- (void)_fetchImage
{
    NSURL *url = [NSURL URLWithString:self.url];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.cachedImageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
         weakSelf.image = image;
         weakSelf.cachedImageView.image = image;
     }failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
         NSLog(@"Error: get message image error: %@", error);
     }];
}

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView
{
    if (self.image)
    {
        return self.cachedImageView;
    }

    if (self.url == nil)
    {
        return nil;
    }

    if (!self.hasFetchedImage)
    {
        self.hasFetchedImage = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _fetchImage];
        });
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
    return super.hash ^ self.url.hash;
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

