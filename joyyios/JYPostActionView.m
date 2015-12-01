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
@property (nonatomic) BOOL didSetupConstraints;
@property (nonatomic) BOOL likeButtonPressed;
@property (nonatomic) UIButton *commentButton;
@property (nonatomic) UIButton *likeButton;
@end

static const CGFloat kButtonWidth = 40;
static const CGFloat kButtonHeight = kButtonWidth;
static const CGFloat kButtonSpace = -20;

@implementation JYPostActionView

+ (instancetype)newAutoLayoutView
{
    JYPostActionView *view = [super newAutoLayoutView];
    [view addSubview:view.likeButton];
    [view addSubview:view.commentButton];

    return view;
}

- (void)updateConstraints
{
    if (!self.didSetupConstraints)
    {
        // size
        [self.likeButton autoSetDimensionsToSize:CGSizeMake(kButtonWidth, kButtonHeight)];
        [self.commentButton autoSetDimensionsToSize:CGSizeMake(kButtonWidth, kButtonHeight)];

        // layout
        [self.likeButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
        [self.commentButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];

        [self.likeButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:kMarginRight];
        [self.commentButton autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.likeButton withOffset:kButtonSpace];

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
    UIButton *button = [UIButton newAutoLayoutView];
    UIImage *image = [normalImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [button setImage:image forState:UIControlStateNormal];

    image = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [button setImage:image forState:UIControlStateSelected];

    button.tintColor = JoyyGray;
    return button;
}

- (UIButton *)_buttonWithImage:(UIImage *)normalImage
{
    UIButton *button = [UIButton newAutoLayoutView];
    UIImage *image = [normalImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [button setImage:image forState:UIControlStateNormal];

    button.tintColor = JoyyGray;
    return button;
}
@end
