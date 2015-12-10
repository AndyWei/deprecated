//
//  JYPosterView.m
//  joyyios
//
//  Created by Ping Yang on 11/26/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIButton+AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYButton.h"
#import "JYFriendManager.h"
#import "JYPost.h"
#import "JYPostOwnerView.h"
#import "NSDate+Joyy.h"

@interface JYPostOwnerView () <TTTAttributedLabelDelegate>
@property (nonatomic) UIButton *avatarButton;
@property (nonatomic) TTTAttributedLabel *posterNameLabel;
@property (nonatomic) TTTAttributedLabel *postTimeLabel;
@end

static NSString *kUsernameURL = @"action://_didTapAvatarButton";

@implementation JYPostOwnerView

- (instancetype)init
{
    if (self = [super init])
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;

        [self addSubview:self.avatarButton];
        [self addSubview:self.posterNameLabel];
        [self addSubview:self.postTimeLabel];

        NSDictionary *views = @{
                                @"avatarButton": self.avatarButton,
                                @"posterNameLabel": self.posterNameLabel,
                                @"postTimeLabel": self.postTimeLabel
                              };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[avatarButton(40)][posterNameLabel][postTimeLabel(50)]-8-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[avatarButton]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[posterNameLabel]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[postTimeLabel]|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)setPost:(JYPost *)post
{
    _post = post;

    if (!_post)
    {
        self.avatarButton.imageView.image = nil;
        self.posterNameLabel.text = nil;
        self.postTimeLabel.text = nil;
        return;
    }

    [self _updateAvatarButtonImage];

    JYFriend *poster = [[JYFriendManager sharedInstance] friendWithId:self.post.ownerId];
    if (poster)
    {
        self.posterNameLabel.text = poster.username;

        // add link to make the label clickable
        NSRange range = [self.posterNameLabel.text rangeOfString:self.posterNameLabel.text];
        [self.posterNameLabel addLinkToURL:[NSURL URLWithString:kUsernameURL] withRange:range];
    }

    NSDate *date = [NSDate dateOfId:self.post.postId];
    self.postTimeLabel.text = [date ageString];
}

- (void)_updateAvatarButtonImage
{
    JYFriend *friend = [[JYFriendManager sharedInstance] friendWithId:self.post.ownerId];
    NSURL *url = [NSURL URLWithString:friend.avatarURL];
    [self.avatarButton setImageForState:UIControlStateNormal withURL:url];
}

- (UIButton *)avatarButton
{
    if (!_avatarButton)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button addTarget:self action:@selector(_didTapAvatarButton) forControlEvents:UIControlEventTouchUpInside];
        button.clipsToBounds = YES;
        button.layer.cornerRadius = 20;

        _avatarButton = button;
    }
    return _avatarButton;
}

- (TTTAttributedLabel *)posterNameLabel
{
    if (!_posterNameLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:kFontSizeCaption];
        label.textColor = JoyyBlue;
        label.backgroundColor = JoyyWhitePure;
        label.textAlignment = NSTextAlignmentLeft;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.delegate = self;

        label.linkAttributes = @{
                                    (NSString*)kCTForegroundColorAttributeName: (__bridge id)(JoyyBlue.CGColor),
                                    (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                               };
        label.activeLinkAttributes = @{
                                          (NSString*)kCTForegroundColorAttributeName: (__bridge id)(FlatSand.CGColor),
                                          (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                                     };

        _posterNameLabel = label;
    }
    return _posterNameLabel;
}

- (TTTAttributedLabel *)postTimeLabel
{
    if (!_postTimeLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
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

- (void)_didTapAvatarButton
{
    NSDictionary *info = @{@"userid": self.post.ownerId};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidTapOnUser object:nil userInfo:info];
}

#pragma mark -- TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if ([kUsernameURL isEqualToString:[url absoluteString]])
    {
        [self _didTapAvatarButton];
    }
}

@end
