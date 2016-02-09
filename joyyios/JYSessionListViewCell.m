//
//  JYSessionListViewCell.m
//  joyyios
//
//  Created by Ping Yang on 9/3/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIKit+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYFriendManager.h"
#import "JYMessageDateFormatter.h"
#import "JYSessionListViewCell.h"

@interface JYSessionListViewCell ()
@property (nonatomic) JYFriend *friend;
@property (nonatomic) TTTAttributedLabel *messageLabel;
@property (nonatomic) TTTAttributedLabel *timeLabel;
@property (nonatomic) TTTAttributedLabel *usernameLabel;
@property (nonatomic) UILabel *redDot;
@property (nonatomic) UIImageView *avatarView;
@end

@implementation JYSessionListViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = JoyyWhitePure;

        [self.contentView addSubview:self.avatarView];
        [self.contentView addSubview:self.messageLabel];
        [self.contentView addSubview:self.redDot];
        [self.contentView addSubview:self.timeLabel];
        [self.contentView addSubview:self.usernameLabel];

        NSDictionary *views = @{
                                @"avatarView": self.avatarView,
                                @"messageLabel": self.messageLabel,
                                @"redDot": self.redDot,
                                @"timeLabel": self.timeLabel,
                                @"usernameLabel": self.usernameLabel,
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarView(50)]-10-[usernameLabel]-(>=10@500)-[timeLabel]-8-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarView(50)]-10-[messageLabel]-(>=8@500)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarView(50)]-(-5)-[redDot(10)]-(>=8@500)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[avatarView(50)]-5@500-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[redDot(10)]-5@500-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[usernameLabel]-5-[messageLabel]-(>=5@500)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[timeLabel]-5-[messageLabel]-(>=5@500)-|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)setMessage:(JYMessage *)message
{
    _message = message;

    if (!message)
    {
        self.messageLabel.text = nil;
        self.friend = nil;
        self.timeLabel.text = nil;
        return;
    }

    self.messageLabel.text = [_message liteText];
    self.friend = [[JYFriendManager sharedInstance] friendWithId:message.peerId];
    self.timeLabel.text = [[JYMessageDateFormatter sharedInstance] autoStringFromDate:message.timestamp];

    self.redDot.alpha = [message.isUnread boolValue]? 1.0f: 0.0f;
}

- (void)setFriend:(JYFriend *)friend
{
    _friend = friend;

    self.usernameLabel.text = friend.username;

    // Fetch avatar image via network
    NSURLRequest *request = [NSURLRequest requestWithURL:friend.avatarThumbnailURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.avatarView setImageWithURLRequest:request
                           placeholderImage:nil
                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                        weakSelf.avatarView.image = image;
                                        weakSelf.friend.avatarThumbnailImage = image;

                                   } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                        NSLog(@"setImageWithURLRequest failed with error = %@", error);
                                   }];
}

- (UILabel *)redDot
{
    if (!_redDot)
    {
        UILabel *label = [UILabel new];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [label setText:@""];
        [label setBackgroundColor:JoyyRedPure];
        label.layer.cornerRadius = 5;
        label.layer.masksToBounds = YES;

        _redDot = label;
    }
    return _redDot;
}

- (UIImageView *)avatarView
{
    if (!_avatarView)
    {
        _avatarView = [UIImageView new];
        _avatarView.translatesAutoresizingMaskIntoConstraints = NO;
        _avatarView.contentMode = UIViewContentModeScaleAspectFit;
        _avatarView.layer.cornerRadius = 25;
        _avatarView.layer.masksToBounds = YES;
    }
    return _avatarView;
}

- (TTTAttributedLabel *)timeLabel
{
    if (!_timeLabel)
    {
        _timeLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _timeLabel.backgroundColor = JoyyWhitePure;
        _timeLabel.font = [UIFont systemFontOfSize:15];
        _timeLabel.textColor = JoyyGray;
        _timeLabel.textAlignment = NSTextAlignmentRight;
    }
    return _timeLabel;
}

- (TTTAttributedLabel *)usernameLabel
{
    if (!_usernameLabel)
    {
        _usernameLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        _usernameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _usernameLabel.backgroundColor = JoyyWhitePure;
        _usernameLabel.font = [UIFont systemFontOfSize:19];
        _usernameLabel.textColor = JoyyBlackPure;
        _usernameLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _usernameLabel;
}

- (TTTAttributedLabel *)messageLabel
{
    if (!_messageLabel)
    {
        _messageLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        _messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _messageLabel.backgroundColor = JoyyWhitePure;
        _messageLabel.font = [UIFont systemFontOfSize:17];
        _messageLabel.textColor = JoyyGray;
        _messageLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _messageLabel;
}

@end
