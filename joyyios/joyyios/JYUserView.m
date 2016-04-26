//
//  JYUserView.m
//  joyyios
//
//  Created by Ping Yang on 11/26/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIButton+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYButton.h"
#import "JYPost.h"
#import "JYUserView.h"
#import "NSDate+Joyy.h"

@interface JYUserView () <TTTAttributedLabelDelegate>
@property (nonatomic) UIButton *avatarButton;
@property (nonatomic) TTTAttributedLabel *usernameLabel;
@property (nonatomic) TTTAttributedLabel *sexLabel;
@end

static NSString *kUsernameURL = @"action://_didTapAvatarButton";

@implementation JYUserView

- (instancetype)init
{
    if (self = [super init])
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.hideDetail = NO;

        [self addSubview:self.avatarButton];
        [self addSubview:self.usernameLabel];
        [self addSubview:self.sexLabel];

        NSDictionary *views = @{
                                @"avatarButton": self.avatarButton,
                                @"usernameLabel": self.usernameLabel,
                                @"sexLabel": self.sexLabel
                              };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[avatarButton]-8-[usernameLabel]-5-[sexLabel(20)]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[avatarButton]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[usernameLabel]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sexLabel]|" options:0 metrics:nil views:views]];

        [self.avatarButton addConstraint:[NSLayoutConstraint constraintWithItem:self.avatarButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.avatarButton attribute:NSLayoutAttributeHeight multiplier:1.0f constant:0.0f]];
    }
    return self;
}

- (void)setUser:(JYUser *)user
{
    _user = user;

    if (!_user)
    {
        self.avatarButton.imageView.image = nil;
        self.usernameLabel.text = nil;
        return;
    }

    [self.avatarButton setImageForState:UIControlStateNormal withURL:user.avatarThumbnailURL];

    // add link to make the label clickable
    self.usernameLabel.text = user.username;
    NSRange range = [self.usernameLabel.text rangeOfString:self.usernameLabel.text];
    [self.usernameLabel addLinkToURL:[NSURL URLWithString:kUsernameURL] withRange:range];

    if (!self.hideDetail)
    {
        self.sexLabel.text = _user.sex;
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

- (TTTAttributedLabel *)usernameLabel
{
    if (!_usernameLabel)
    {
        _usernameLabel = [self _defaultLabel];
        _usernameLabel.delegate = self;
        _usernameLabel.font = [UIFont systemFontOfSize:kFontSizeCaption];
        _usernameLabel.textAlignment = NSTextAlignmentLeft;
        _usernameLabel.linkAttributes = @{
                                 (NSString*)kCTForegroundColorAttributeName: (__bridge id)(JoyyBlue.CGColor),
                                 (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                                 };
        _usernameLabel.activeLinkAttributes = @{
                                       (NSString*)kCTForegroundColorAttributeName: (__bridge id)(FlatSand.CGColor),
                                       (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                                       };
    }
    return _usernameLabel;
}

- (TTTAttributedLabel *)sexLabel
{
    if (!_sexLabel)
    {
        _sexLabel = [self _defaultLabel];
    }
    return _sexLabel;
}

- (TTTAttributedLabel *)_defaultLabel
{
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont systemFontOfSize:kFontSizeComment];
    label.textColor = JoyyGray;
    label.backgroundColor = JoyyWhitePure;
    label.textAlignment = NSTextAlignmentRight;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;

    return label;
}

- (void)_didTapAvatarButton
{
    if (self.notificationName)
    {
        NSDictionary *info = @{@"userid": self.user.userId};
        [[NSNotificationCenter defaultCenter] postNotificationName:self.notificationName object:nil userInfo:info];
    }
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
