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
#import "JYFriendView.h"
#import "NSDate+Joyy.h"

@interface JYFriendView () <TTTAttributedLabelDelegate>
@property (nonatomic) UIButton *avatarButton;
@property (nonatomic) TTTAttributedLabel *posterNameLabel;
@end

static NSString *kUsernameURL = @"action://_didTapAvatarButton";

@implementation JYFriendView

- (instancetype)init
{
    if (self = [super init])
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;

        [self addSubview:self.avatarButton];
        [self addSubview:self.posterNameLabel];
        

        NSDictionary *views = @{
                                @"avatarButton": self.avatarButton,
                                @"posterNameLabel": self.posterNameLabel
                              };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[avatarButton(40)][posterNameLabel]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[avatarButton]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[posterNameLabel]|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)setUser:(JYFriend *)user
{
    _user = user;

    if (!_user)
    {
        self.avatarButton.imageView.image = nil;
        self.posterNameLabel.text = nil;
        return;
    }

    [self _updateAvatarButtonImage];

    self.posterNameLabel.text = user.username;

    // add link to make the label clickable
    NSRange range = [self.posterNameLabel.text rangeOfString:self.posterNameLabel.text];
    [self.posterNameLabel addLinkToURL:[NSURL URLWithString:kUsernameURL] withRange:range];
}

- (void)_updateAvatarButtonImage
{
    if (self.user)
    {
        NSURL *url = [NSURL URLWithString:self.user.avatarURL];
        [self.avatarButton setImageForState:UIControlStateNormal withURL:url];
    }
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

- (void)_didTapAvatarButton
{
    NSDictionary *info = @{@"userid": self.user.userId};
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
