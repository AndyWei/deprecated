//
//  JYMediaView.m
//  joyyios
//
//  Created by Ping Yang on 11/30/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIKit+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYPostMediaView.h"
#import "JYPost.h"

@interface JYPostMediaView ()
@property (nonatomic) TTTAttributedLabel *captionLabel;
@property (nonatomic) UIImageView *photoView;
@end

@implementation JYPostMediaView

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

                                       if (!weakSelf.post.localImage)
                                       {
                                            weakSelf.photoView.alpha = 0;
                                           [UIView animateWithDuration:0.5 animations:^{
                                               weakSelf.photoView.alpha = 1;
                                           }];
                                       }
                                       weakSelf.post.localImage = image;

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
        _photoView.userInteractionEnabled = YES;

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_didTapPhotoView)];
        tap.numberOfTapsRequired = 1;
        [_photoView addGestureRecognizer:tap];
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

- (void)_didTapPhotoView
{
    if (self.delegate)
    {
        [self.delegate view:self didTapOnPost:self.post];
    }
}

@end
