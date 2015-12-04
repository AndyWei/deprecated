//
//  JYMediaView.m
//  joyyios
//
//  Created by Ping Yang on 11/30/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYMediaView.h"
#import "JYPost.h"

@interface JYMediaView ()
@property (nonatomic) TTTAttributedLabel *captionLabel;
@property (nonatomic) UIImageView *photoView;
@end

@implementation JYMediaView

- (instancetype)init
{
    if (self = [super init])
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;

        [self addSubview:self.photoView];
        [self addSubview:self.captionLabel];

        NSDictionary *views = @{
                                @"photoView": self.photoView
                              };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[photoView]-0-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[photoView]-0-|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)setPost:(JYPost *)post
{
    if (_post == post)
    {
        return;
    }

    _post = post;

    [self _updatePhoto];
    [self _updateCaption];
}

- (void)_updatePhoto
{
    if (!_post)
    {
        self.photoView.image = nil;
        return;
    }

    // Fetch network image
    NSURL *url = [NSURL URLWithString:self.post.URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.photoView setImageWithURLRequest:request
                          placeholderImage:self.post.localImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       weakSelf.photoView.image = image;
                                       weakSelf.photoView.alpha = 0;
                                       weakSelf.post.localImage = nil;
                                       [UIView animateWithDuration:0.5 animations:^{
                                           weakSelf.photoView.alpha = 1;
                                       }];
                                   } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                       NSLog(@"setImageWithURLRequest failed with error = %@", error);
                                   }];
}

- (void)_updateCaption
{
    if (!_post)
    {
        self.captionLabel.text = nil;
        return;
    }

    self.captionLabel.text = self.post.caption;
    self.captionLabel.width = SCREEN_WIDTH - 30;

    [self.captionLabel sizeToFit];
    self.captionLabel.centerX = SCREEN_WIDTH/2;
    self.captionLabel.y = SCREEN_WIDTH - self.captionLabel.height - 10;
}

- (UIImageView *)photoView
{
    if (!_photoView)
    {
        _photoView = [[UIImageView alloc] init];
        _photoView.translatesAutoresizingMaskIntoConstraints = NO;
        _photoView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _photoView;
}

- (TTTAttributedLabel *)captionLabel
{
    if (!_captionLabel)
    {
        _captionLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        _captionLabel.preferredMaxLayoutWidth = SCREEN_WIDTH - 30;
        _captionLabel.textInsets = UIEdgeInsetsMake(0, kMarginLeft, 0, kMarginRight);

        _captionLabel.backgroundColor = JoyyBlack80;
        _captionLabel.textColor = JoyyWhite;
        _captionLabel.font = [UIFont systemFontOfSize:kFontSizeCaption];
        _captionLabel.textAlignment = NSTextAlignmentCenter;

        _captionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _captionLabel.numberOfLines = 0;

        _captionLabel.layer.cornerRadius = 4;
        _captionLabel.clipsToBounds = YES;
    }
    return _captionLabel;
}

@end
