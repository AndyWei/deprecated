//
//  JYPosterView.m
//  joyyios
//
//  Created by Ping Yang on 11/26/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYButton.h"
#import "JYFriendsManager.h"
#import "JYPost.h"
#import "JYPosterView.h"
#import "NSDate+Joyy.h"

@interface JYPosterView ()
@property (nonatomic) BOOL didSetupConstraints;
@property (nonatomic) UIButton *avatarButton;
@property (nonatomic) TTTAttributedLabel *posterNameLabel;
@property (nonatomic) TTTAttributedLabel *postTimeLabel;
@end


static const CGFloat kButtonWidth = 40;
static const CGFloat kButtonHeight = kButtonWidth;
static const CGFloat kPostTimeLabelWidth = 50;

@implementation JYPosterView

+ (instancetype)newAutoLayoutView
{
    JYPosterView *view = [super newAutoLayoutView];
    [view addSubview:view.avatarButton];
    [view addSubview:view.posterNameLabel];
    [view addSubview:view.postTimeLabel];
    return view;
}

- (void)updateConstraints
{
    if (!self.didSetupConstraints)
    {
        // size
        [self.avatarButton autoSetDimensionsToSize:CGSizeMake(kButtonWidth, kButtonHeight)];
        [self.postTimeLabel autoSetDimensionsToSize:CGSizeMake(kPostTimeLabelWidth, kButtonHeight)];
        [@[self.posterNameLabel, self.postTimeLabel] autoSetViewsDimension:ALDimensionHeight toSize:kButtonHeight];

        // layout
        [self.avatarButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:kMarginLeft];
        [self.postTimeLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:kMarginRight];
        [self.posterNameLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.avatarButton withOffset:kMarginLeft];
        [self.posterNameLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.postTimeLabel];

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

    [self _updateAvatarButtonImage];

    self.posterNameLabel.text = [[JYDataStore sharedInstance] usernameOfId:self.post.ownerId];

    NSDate *date = [NSDate dateOfId:self.post.postId];
    self.postTimeLabel.text = [date ageString];
}

- (void)_updateAvatarButtonImage
{
    JYUser *owner = [[JYFriendsManager sharedInstance] userOfId:self.post.ownerId];
    NSURL *url = [NSURL URLWithString:owner.avatarURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.avatarButton.imageView setImageWithURLRequest:request
                                       placeholderImage:nil
                                                success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                    weakSelf.avatarButton.imageView.image = image;

                                                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                    NSLog(@"setImageWithURLRequest failed with response = %@", response);
                                                }];
}

- (UIButton *)avatarButton
{
    if (!_avatarButton)
    {
        UIButton *button = [UIButton newAutoLayoutView];
        [button addTarget:self action:@selector(_showProfile) forControlEvents:UIControlEventTouchUpInside];
        [button setImage:[UIImage imageNamed:@"wink"] forState:UIControlStateNormal];
        button.clipsToBounds = YES;
        button.layer.cornerRadius = kButtonWidth/2;
        button.contentEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);

        _avatarButton = button;
    }
    return _avatarButton;
}

- (TTTAttributedLabel *)posterNameLabel
{
    if (!_posterNameLabel)
    {
        TTTAttributedLabel *label = [TTTAttributedLabel newAutoLayoutView];
        label.font = [UIFont systemFontOfSize:kFontSizeDetail];
        label.textColor = JoyyBlue;
        label.backgroundColor = JoyyWhitePure;
        label.textAlignment = NSTextAlignmentLeft;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;

        _posterNameLabel = label;
    }
    return _posterNameLabel;
}

- (TTTAttributedLabel *)postTimeLabel
{
    if (!_postTimeLabel)
    {
        TTTAttributedLabel *label = [TTTAttributedLabel newAutoLayoutView];
        label.font = [UIFont systemFontOfSize:kFontSizeDetail];
        label.textColor = JoyyGray;
        label.backgroundColor = JoyyWhitePure;
        label.textAlignment = NSTextAlignmentRight;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;

        _postTimeLabel = label;
    }
    return _postTimeLabel;
}

- (void)_showProfile
{

}

@end
