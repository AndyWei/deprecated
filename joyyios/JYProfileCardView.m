//
//  JYProfileCardView.m
//  joyyios
//
//  Created by Ping Yang on 12/23/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIButton+AFNetworking.h>

#import "JYProfileCardView.h"

@interface JYProfileCardView ()
@property (nonatomic) UIButton *avatarButton;
@property (nonatomic) TTTAttributedLabel *usernameLabel;
@property (nonatomic) TTTAttributedLabel *friendCountLabel;
@property (nonatomic) TTTAttributedLabel *winkCountLabel;
@end

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
        [self addSubview:self.winkCountLabel];

        NSDictionary *views = @{
                                @"avatarButton": self.avatarButton,
                                @"usernameLabel": self.usernameLabel,
                                @"friendCountLabel": self.friendCountLabel,
                                @"winkCountLabel": self.winkCountLabel
                                };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarButton(80)]-60-[friendCountLabel(80)]-10-[winkCountLabel(80)]-(>=0@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[usernameLabel(300)]-(>=10@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[avatarButton(80)]-10-[usernameLabel]-10-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[friendCountLabel]-(>=10@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[winkCountLabel]-(>=10@500)-|" options:0 metrics:nil views:views]];
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

- (void)setFriendCount:(uint32_t)friendCount
{
    NSString *friends = NSLocalizedString(@"friends", nil);
    self.friendCountLabel.text = [NSString stringWithFormat:@"%u \n %@", friendCount, friends];
}

- (void)setWinkCount:(uint32_t)winkCount
{
    NSString *winks = NSLocalizedString(@"winks", nil);
    self.winkCountLabel.text = [NSString stringWithFormat:@"%u \n %@", winkCount, winks];
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
        TTTAttributedLabel *label = [self _defaultLabel];
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
        _friendCountLabel = [self _defaultLabel];
    }
    return _friendCountLabel;
}

- (TTTAttributedLabel *)winkCountLabel
{
    if (!_winkCountLabel)
    {
        _winkCountLabel = [self _defaultLabel];
    }
    return _winkCountLabel;
}

- (TTTAttributedLabel *)_defaultLabel
{
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont systemFontOfSize:kFontSizeDetail];
    label.backgroundColor = ClearColor;
    label.textColor = JoyyBlue;
    label.textAlignment = NSTextAlignmentCenter;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.preferredMaxLayoutWidth = 80;

    return label;
}

- (void)_didTapAvatarButton
{

}

@end
