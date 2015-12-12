//
//  JYPostActionView.m
//  joyyios
//
//  Created by Ping Yang on 11/26/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYButton.h"
#import "JYLocalDataManager.h"
#import "JYPost.h"
#import "JYPostActionView.h"

@interface JYPostActionView ()
@property (nonatomic) BOOL likeButtonPressed;
@property (nonatomic) JYButton *commentButton;
@property (nonatomic) JYButton *likeButton;
@property (nonatomic) UIView *separator;
@end

@implementation JYPostActionView

- (instancetype)init
{
    if (self = [super init])
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;

        [self addSubview:self.likeButton];
        [self addSubview:self.commentButton];
        [self addSubview:self.separator];

        NSDictionary *views = @{
                                @"commentButton": self.commentButton,
                                @"likeButton": self.likeButton,
                                @"separator": self.separator
                                };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=10)-[likeButton(40)]-20-[commentButton(40)]-10-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(20)-[separator]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[commentButton][separator(0.5)]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[likeButton][separator(0.5)]|" options:0 metrics:nil views:views]];

    }
    return self;
}

- (void)setPost:(JYPost *)post
{
    _post = post;

    if (!_post)
    {
        self.likeButtonPressed = NO;
        self.likeButton.imageView.image = [UIImage imageNamed:@"heart"];
        self.likeButton.contentColor = JoyyGray;
        return;
    }

    self.likeButtonPressed = NO;
    [self _updateLikeButtonImage];
}

- (void)_updateLikeButtonImage
{
    if ([self.post isLikedByMe])
    {
        self.likeButton.imageView.image = [UIImage imageNamed:@"heart_selected"];
        self.likeButton.contentColor = JoyyBlue;
    }
    else
    {
        self.likeButton.imageView.image = [UIImage imageNamed:@"heart"];
        self.likeButton.contentColor = JoyyGray;
    }
}

- (JYButton *)commentButton
{
    if (!_commentButton)
    {
        _commentButton = [self _buttonWithImage:[UIImage imageNamed:@"comment"]];
        _commentButton.contentEdgeInsets = UIEdgeInsetsMake(9, 8, 7, 8);
        [_commentButton addTarget:self action:@selector(_didTapCommentButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _commentButton;
}

- (JYButton *)likeButton
{
    if (!_likeButton)
    {
        _likeButton = [self _buttonWithImage:[UIImage imageNamed:@"heart"]];
        _likeButton.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
        [_likeButton addTarget:self action:@selector(_didTapLikeButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _likeButton;
}

- (UIView *)separator
{
    if (!_separator)
    {
        _separator = [[UIView alloc] initWithFrame:CGRectZero];
        _separator.translatesAutoresizingMaskIntoConstraints = NO;
        _separator.backgroundColor = JoyyWhite;
    }
    return _separator;
}

- (void)_didTapCommentButton
{
    NSDictionary *info = @{@"post": self.post};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCreateComment object:nil userInfo:info];
}

- (void)_didTapLikeButton
{
    if (!self.post || self.likeButtonPressed || [self.post isLikedByMe])
    {
        return;
    }

    self.likeButtonPressed = YES;

    NSDictionary *info = @{@"post": self.post};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWillLikePost object:nil userInfo:info];
}

- (JYButton *)_buttonWithImage:(UIImage *)image
{
    JYButton *button = [JYButton buttonWithFrame:CGRectZero buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.imageView.image = image;
    button.contentColor = JoyyGray;
    button.contentAnimateToColor = JoyyBlue;
    button.foregroundColor = ClearColor;

    return button;
}
@end
