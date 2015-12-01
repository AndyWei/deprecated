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
@property (nonatomic) BOOL didSetupConstraints;
@property (nonatomic) TTTAttributedLabel *captionLabel;
@property (nonatomic) UIImageView *photoView;
@end

@implementation JYMediaView

+ (instancetype)newAutoLayoutView
{
    JYMediaView *view = [super newAutoLayoutView];
    [view addSubview:view.photoView];
    [view addSubview:view.captionLabel];

    return view;
}

- (void)updateConstraints
{
    if (!self.didSetupConstraints)
    {
        [self.photoView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
        [self.photoView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
        [self.photoView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
        [self.photoView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];

        [self.captionLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.captionLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10];

        self.didSetupConstraints = YES;
    }
    [super updateConstraints];
}

- (void)setPost:(JYPost *)post
{
    if (!post)
    {
        NSAssert(NO, @"post should not be nil");
        return;
    }

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
    // Fetch network image
    NSURL *url = [NSURL URLWithString:_post.URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.photoView setImageWithURLRequest:request
                          placeholderImage:nil
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       weakSelf.photoView.image = image;
                                       weakSelf.photoView.alpha = 0;
                                       [UIView animateWithDuration:0.5 animations:^{
                                           weakSelf.photoView.alpha = 1;
                                       }];
                                   } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                       NSLog(@"setImageWithURLRequest response = %@", response);
                                   }];
}

- (void)_updateCaption
{
    self.captionLabel.text = self.post.caption;
    self.captionLabel.width = SCREEN_WIDTH;
    self.captionLabel.preferredMaxLayoutWidth = SCREEN_WIDTH - kMarginLeft - kMarginRight;
    self.captionLabel.textInsets = UIEdgeInsetsMake(0, kMarginLeft, 0, kMarginRight);
    
    [self.captionLabel sizeToFit];
}

- (UIImageView *)photoView
{
    if (!_photoView)
    {
        _photoView = [[UIImageView alloc] init];
        [_photoView configureForAutoLayout];
        _photoView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _photoView;
}

- (TTTAttributedLabel *)captionLabel
{
    if (!_captionLabel)
    {
        CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, 0);
        _captionLabel = [[TTTAttributedLabel alloc] initWithFrame:frame];
        _captionLabel.backgroundColor = JoyyBlack80;
        _captionLabel.textColor = JoyyWhite;
        _captionLabel.font = [UIFont systemFontOfSize:kFontSizeCaption];
        _captionLabel.textAlignment = NSTextAlignmentCenter;

        _captionLabel.layer.cornerRadius = 4;
        _captionLabel.clipsToBounds = YES;
    }
    return _captionLabel;
}

@end
