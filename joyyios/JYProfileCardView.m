//
//  JYProfileCardView.m
//  joyyios
//
//  Created by Ping Yang on 12/23/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIButton+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYProfileCardView.h"

@interface JYProfileCardView () <TTTAttributedLabelDelegate>
@property (nonatomic) UIButton *avatarButton;
@property (nonatomic) TTTAttributedLabel *usernameLabel;
@property (nonatomic) TTTAttributedLabel *friendCountLabel;
@property (nonatomic) TTTAttributedLabel *friendsLabel;
@property (nonatomic) TTTAttributedLabel *inviteCountLabel;
@property (nonatomic) TTTAttributedLabel *invitesLabel;
@property (nonatomic) TTTAttributedLabel *winkCountLabel;
@property (nonatomic) TTTAttributedLabel *winksLabel;
@end

static NSString *kFriendURL = @"action://_didTapFriendLabel";
static NSString *kInviteURL = @"action://_didTapInviteLabel";
static NSString *kWinkURL = @"action://_didTapWinkLabel";

@implementation JYProfileCardView

- (id)init
{
    self = [super init];
    if (self)
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = JoyyWhitePure;

        [self addSubview:self.avatarButton];
        [self addSubview:self.usernameLabel];
        [self addSubview:self.friendCountLabel];
        [self addSubview:self.friendsLabel];
        [self addSubview:self.inviteCountLabel];
        [self addSubview:self.invitesLabel];
        [self addSubview:self.winkCountLabel];
        [self addSubview:self.winksLabel];

        self.friendCount = self.inviteCount = self.winkCount = 0;

        NSDictionary *views = @{
                                @"avatarButton": self.avatarButton,
                                @"usernameLabel": self.usernameLabel,
                                @"friendCountLabel": self.friendCountLabel,
                                @"friendsLabel": self.friendsLabel,
                                @"inviteCountLabel": self.inviteCountLabel,
                                @"invitesLabel": self.invitesLabel,
                                @"winkCountLabel": self.winkCountLabel,
                                @"winksLabel": self.winksLabel
                                };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarButton(80)]-20-[friendCountLabel(60)]-10-[inviteCountLabel(60)]-10-[winkCountLabel(60)]-(>=0@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarButton(80)]-20-[friendsLabel(60)]-10-[invitesLabel(60)]-10-[winksLabel(60)]-(>=0@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[usernameLabel(300)]-(>=10@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[avatarButton(80)]-10-[usernameLabel]-10-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[friendCountLabel][friendsLabel]-(>=10@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[inviteCountLabel][invitesLabel]-(>=10@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[winkCountLabel][winksLabel]-(>=10@500)-|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)setUser:(JYUser *)user
{
    if (_user == user || !user)
    {
        return;
    }

    _user = user;

    NSURL *url = [NSURL URLWithString:user.avatarURL];
    [self.avatarButton setImageForState:UIControlStateNormal withURL:url];

    self.usernameLabel.text = user.username;
}

- (void)setFriendCount:(uint64_t)friendCount
{
    _friendCount = friendCount;
    NSString *count = [NSString stringWithFormat:@"%llu", friendCount];
    self.friendCountLabel.text = count;

    NSRange range = [count rangeOfString:count];
    [self.friendCountLabel addLinkToURL:[NSURL URLWithString:kFriendURL] withRange:range];
}

- (void)setInviteCount:(uint64_t)inviteCount
{
    _inviteCount = inviteCount;
    NSString *count = [NSString stringWithFormat:@"%llu", inviteCount];
    self.inviteCountLabel.text = count;

    NSRange range = [count rangeOfString:count];
    [self.inviteCountLabel addLinkToURL:[NSURL URLWithString:kInviteURL] withRange:range];
}

- (void)setWinkCount:(uint64_t)winkCount
{
    _winkCount = winkCount;
    NSString *count = [NSString stringWithFormat:@"%llu", winkCount];
    self.winkCountLabel.text = count;

    NSRange range = [count rangeOfString:count];
    [self.winkCountLabel addLinkToURL:[NSURL URLWithString:kWinkURL] withRange:range];
}

- (UIButton *)avatarButton
{
    if (!_avatarButton)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button addTarget:self action:@selector(_didTapAvatarButton) forControlEvents:UIControlEventTouchUpInside];
        button.clipsToBounds = YES;
        button.layer.cornerRadius = 40;

        _avatarButton = button;
    }
    return _avatarButton;
}

- (TTTAttributedLabel *)usernameLabel
{
    if (!_usernameLabel)
    {
        TTTAttributedLabel *label = [self _propertyLabel];
        label.font = [UIFont systemFontOfSize:kFontSizeCaption];
        label.textAlignment = NSTextAlignmentLeft;
        label.preferredMaxLayoutWidth = 300;

        _usernameLabel = label;
    }
    return _usernameLabel;
}

- (TTTAttributedLabel *)friendCountLabel
{
    if (!_friendCountLabel)
    {
        _friendCountLabel = [self _countLabel];
    }
    return _friendCountLabel;
}

- (TTTAttributedLabel *)friendsLabel
{
    if (!_friendsLabel)
    {
        _friendsLabel = [self _propertyLabel];

        _friendsLabel.text = NSLocalizedString(@"friends", nil);
        NSRange range = [_friendsLabel.text rangeOfString:_friendsLabel.text];
        [_friendsLabel addLinkToURL:[NSURL URLWithString:kFriendURL] withRange:range];
    }
    return _friendsLabel;
}

- (TTTAttributedLabel *)inviteCountLabel
{
    if (!_inviteCountLabel)
    {
        _inviteCountLabel = [self _countLabel];
    }
    return _inviteCountLabel;
}

- (TTTAttributedLabel *)invitesLabel
{
    if (!_invitesLabel)
    {
        _invitesLabel = [self _propertyLabel];

        _invitesLabel.text = NSLocalizedString(@"invites", nil);
        NSRange range = [_invitesLabel.text rangeOfString:_invitesLabel.text];
        [_invitesLabel addLinkToURL:[NSURL URLWithString:kInviteURL] withRange:range];
    }
    return _invitesLabel;
}

- (TTTAttributedLabel *)winkCountLabel
{
    if (!_winkCountLabel)
    {
        _winkCountLabel = [self _countLabel];
    }
    return _winkCountLabel;
}

- (TTTAttributedLabel *)winksLabel
{
    if (!_winksLabel)
    {
        _winksLabel = [self _propertyLabel];
        _winksLabel.linkAttributes = @{
                                           (NSString*)kCTForegroundColorAttributeName: (__bridge id)(JoyyGray.CGColor),
                                           (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                                           };

        _winksLabel.text = NSLocalizedString(@"winks", nil);
        NSRange range = [_winksLabel.text rangeOfString:_winksLabel.text];
        [_winksLabel addLinkToURL:[NSURL URLWithString:kWinkURL] withRange:range];
    }
    return _winksLabel;
}

- (TTTAttributedLabel *)_countLabel
{
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = ClearColor;
    label.delegate = self;
    label.font = [UIFont systemFontOfSize:kFontSizeDetail];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.preferredMaxLayoutWidth = 80;
    label.textColor = JoyyGray;
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;

    UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:14];
    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
    label.linkAttributes = @{
                             (NSString *)kCTFontAttributeName: (__bridge id)font,
                             (NSString*)kCTForegroundColorAttributeName: (__bridge id)(JoyyBlue.CGColor),
                             (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                            };

    label.activeLinkAttributes = @{
                                   (NSString*)kCTForegroundColorAttributeName: (__bridge id)(FlatSand.CGColor),
                                   (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                                   };
    return label;
}

- (TTTAttributedLabel *)_propertyLabel
{
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = ClearColor;
    label.delegate = self;
    label.font = [UIFont systemFontOfSize:kFontSizeDetail];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.preferredMaxLayoutWidth = 80;
    label.textColor = JoyyBlack;
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;

    label.linkAttributes = @{
                              (NSString*)kCTForegroundColorAttributeName: (__bridge id)(JoyyGray.CGColor),
                              (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                            };

    label.activeLinkAttributes = @{
                                   (NSString*)kCTForegroundColorAttributeName: (__bridge id)(FlatSand.CGColor),
                                   (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                                 };
    return label;
}

- (void)_didTapAvatarButton
{

}

#pragma mark -- TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if ([kFriendURL isEqualToString:[url absoluteString]])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidTapOnFriendCount object:nil userInfo:nil];
    }
    else if ([kInviteURL isEqualToString:[url absoluteString]])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidTapOnInviteCount object:nil userInfo:nil];
    }
    else if ([kWinkURL isEqualToString:[url absoluteString]])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidTapOnWinkCount object:nil userInfo:nil];
    }
}

@end
