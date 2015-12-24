//
//  JYUserCell.m
//  joyyios
//
//  Created by Ping Yang on 12/10/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYButton.h"
#import "JYUser.h"
#import "JYUserCell.h"
#import "JYUserView.h"

@interface JYUserCell ()
@property (nonatomic) JYButton *chatButton;
@property (nonatomic) JYUserView *userView;
@end

@implementation JYUserCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = JoyyWhitePure;

        [self.contentView addSubview:self.chatButton];
        [self.contentView addSubview:self.userView];

        NSDictionary *views = @{
                                @"chatButton": self.chatButton,
                                @"userView": self.userView
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[userView]-30-[chatButton(60)]-30-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[chatButton(30)]-(>=15@500)-|" options:0 metrics:nil views:views]];
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

- (JYButton *)chatButton
{
    if (!_chatButton)
    {
        _chatButton = [JYButton buttonWithFrame:CGRectZero buttonStyle:JYButtonStyleTitle appearanceIdentifier:nil];
        _chatButton.cornerRadius = 4;
        _chatButton.contentColor = JoyyWhitePure;
        _chatButton.contentAnimateToColor = FlatGreen;
        _chatButton.foregroundColor = FlatGreen;
        _chatButton.foregroundAnimateToColor = JoyyWhitePure;
        _chatButton.textLabel.text = NSLocalizedString(@"chat", nil);
        _chatButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_chatButton addTarget:self action:@selector(_chat) forControlEvents:UIControlEventTouchUpInside];
    }
    return _chatButton;
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

- (void)_chat
{
    NSDictionary *info = @{@"user": self.user};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWillStartChat object:nil userInfo:info];
}


@end
