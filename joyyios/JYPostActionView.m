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
#import "NSDate+Joyy.h"

@interface JYPostActionView ()
@property (nonatomic) BOOL likeButtonPressed;
@property (nonatomic) UIButton *commentButton;
@property (nonatomic) UIButton *likeButton;
@end

@implementation JYPostActionView

- (instancetype)init
{
    if (self = [super init])
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;

        [self addSubview:self.likeButton];
        [self addSubview:self.commentButton];

        NSDictionary *views = @{
                                @"commentButton": self.commentButton,
                                @"likeButton": self.likeButton
                                };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=10)-[likeButton(40)]-40-[commentButton(40)]-10-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[commentButton]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[likeButton]|" options:0 metrics:nil views:views]];

    }
    return self;
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

    self.likeButtonPressed = NO;
    [self _updateLikeButtonImage];
}

- (void)_updateLikeButtonImage
{
    if (self.post.isLiked)
    {
        self.likeButton.tintColor = JoyyBlue;
    }
    else
    {
        self.likeButton.tintColor = JoyyGray;
    }
}

- (UIButton *)commentButton
{
    if (!_commentButton)
    {
        _commentButton = [self _buttonWithImage:[UIImage imageNamed:@"comment"]];
        _commentButton.contentEdgeInsets = UIEdgeInsetsMake(9, 8, 7, 8);
        [_commentButton addTarget:self action:@selector(_comment) forControlEvents:UIControlEventTouchUpInside];
    }
    return _commentButton;
}

- (UIButton *)likeButton
{
    if (!_likeButton)
    {
        _likeButton = [self _buttonWithNormalImage:[UIImage imageNamed:@"heart"] selectedImage:[UIImage imageNamed:@"heart_selected"]];
        _likeButton.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
        [_likeButton addTarget:self action:@selector(_like) forControlEvents:UIControlEventTouchUpInside];
    }
    return _likeButton;
}

- (void)_comment
{
    NSLog(@"_comment");
    NSDictionary *info = @{@"post": self.post, @"edit":@(YES)};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWillCommentPost object:nil userInfo:info];
}

- (void)_like
{
    NSLog(@"_like");
    if (!self.post || self.post.isLiked || self.likeButtonPressed)
    {
        return;
    }

    self.likeButtonPressed = YES;

    NSDictionary *info = @{@"post": self.post};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWillLikePost object:nil userInfo:info];
}

- (UIButton *)_buttonWithNormalImage:(UIImage *)normalImage selectedImage:(UIImage *)selectedImage
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *image = [normalImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [button setImage:image forState:UIControlStateNormal];

    image = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [button setImage:image forState:UIControlStateSelected];

    button.tintColor = JoyyGray;
    return button;
}

- (UIButton *)_buttonWithImage:(UIImage *)normalImage
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *image = [normalImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [button setImage:image forState:UIControlStateNormal];

    button.tintColor = JoyyGray;
    return button;
}
@end
