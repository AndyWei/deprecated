//
//  JYUserBaseCell.m
//  joyyios
//
//  Created by Ping Yang on 1/5/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "JYUser.h"
#import "JYUserBaseCell.h"

@interface JYUserBaseCell ()
@end

@implementation JYUserBaseCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = JoyyWhitePure;

        [self.contentView addSubview:self.actionButton];
        [self.contentView addSubview:self.userView];
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

- (JYButton *)actionButton
{
    if (!_actionButton)
    {
        _actionButton = [JYButton buttonWithFrame:CGRectZero buttonStyle:JYButtonStyleTitle appearanceIdentifier:nil];
        _actionButton.cornerRadius = 4;
        _actionButton.contentColor = JoyyWhitePure;
        _actionButton.contentAnimateToColor = FlatGreen;
        _actionButton.foregroundColor = FlatGreen;
        _actionButton.foregroundAnimateToColor = JoyyWhitePure;
        _actionButton.textLabel.text = NSLocalizedString(@"action", nil);
        _actionButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_actionButton addTarget:self action:@selector(_action) forControlEvents:UIControlEventTouchUpInside];
    }
    return _actionButton;
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

- (void)_action
{
    if (self.delegate)
    {
        [self.delegate didTapActionButtonOnCell:self];
    }
}


@end

