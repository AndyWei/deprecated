//
//  JYWinkCell.m
//  joyyios
//
//  Created by Ping Yang on 12/23/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYButton.h"
#import "JYUser.h"
#import "JYUserView.h"
#import "JYWinkCell.h"

@interface JYWinkCell ()
@property (nonatomic) JYButton *acceptButton;
@property (nonatomic) JYUserView *userView;
@end

@implementation JYWinkCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = JoyyWhitePure;

        [self.contentView addSubview:self.acceptButton];
        [self.contentView addSubview:self.userView];

        NSDictionary *views = @{
                                @"acceptButton": self.acceptButton,
                                @"userView": self.userView
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[userView]-30-[acceptButton(80)]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[acceptButton(30)]-(>=15@500)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[userView(40)]-(>=10@500)-|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.user = nil;
}

- (void)setUser:(JYUser *)user
{
    _user = user;
    self.userView.user = user;
}

- (JYButton *)acceptButton
{
    if (!_acceptButton)
    {
        _acceptButton = [JYButton buttonWithFrame:CGRectZero buttonStyle:JYButtonStyleTitle appearanceIdentifier:nil];
        _acceptButton.cornerRadius = 4;
        _acceptButton.contentColor = JoyyWhitePure;
        _acceptButton.contentAnimateToColor = FlatGreen;
        _acceptButton.foregroundColor = FlatGreen;
        _acceptButton.foregroundAnimateToColor = JoyyWhitePure;
        _acceptButton.textLabel.text = NSLocalizedString(@"accept", nil);
        _acceptButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_acceptButton addTarget:self action:@selector(_accept) forControlEvents:UIControlEventTouchUpInside];
    }
    return _acceptButton;
}

- (JYUserView *)userView
{
    if (!_userView)
    {
        _userView = [[JYUserView alloc] init];
        _userView.notificationName = nil;
    }
    return _userView;
}

- (void)_accept
{
     NSDictionary *info = @{@"user": self.user};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidAcceptWink object:nil userInfo:info];
}

@end

