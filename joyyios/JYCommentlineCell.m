//
//  JYCommentlineCell.m
//  joyyios
//
//  Created by Ping Yang on 5/14/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIButton+AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYButton.h"
#import "JYCommentlineCell.h"
#import "JYFriendManager.h"

@interface JYCommentlineCell ()
@property(nonatomic) TTTAttributedLabel *commentLabel;
@property(nonatomic) TTTAttributedLabel *usernameLabel;
@property(nonatomic) UIButton *avatarButton;
@end

@implementation JYCommentlineCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = JoyyBlack50;

        [self.contentView addSubview:self.avatarButton];
        [self.contentView addSubview:self.commentLabel];
        [self.contentView addSubview:self.usernameLabel];

        NSDictionary *views = @{
                                @"avatarButton": self.avatarButton,
                                @"commentLabel": self.commentLabel,
                                @"usernameLabel": self.usernameLabel
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarButton(40)]-10-[usernameLabel]-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarButton(40)]-10-[commentLabel]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[avatarButton(40)]-5@500-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[usernameLabel][commentLabel]-5-|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.comment = nil;
}

- (void)setComment:(JYComment *)comment
{
    if (!comment)
    {
        [self.avatarButton setImage:nil forState:UIControlStateNormal];
        self.commentLabel.text = nil;
        self.usernameLabel.text = nil;
        return;
    }

    _comment = comment;

    JYFriend *owner = [[JYFriendManager sharedInstance] friendWithId:comment.ownerId];
    self.usernameLabel.text = owner.username;

    // commentLabel
    JYFriend *replyTo = ([comment.replyToId unsignedLongLongValue] == 0) ? nil: [[JYFriendManager sharedInstance] friendWithId:comment.replyToId];
    NSString *replyText = NSLocalizedString(@"reply", nil);
    if (replyTo)
    {
        self.commentLabel.text = [NSString stringWithFormat:@"%@ %@: %@", replyText, replyTo.username, comment.content];
    }
    else
    {
        self.commentLabel.text = comment.content;
    }

    [self _updateAvatarButtonImage];
}

- (void)_updateAvatarButtonImage
{
    JYFriend *friend = [[JYFriendManager sharedInstance] friendWithId:self.comment.ownerId];
    NSURL *url = [NSURL URLWithString:friend.avatarURL];
    [self.avatarButton setImageForState:UIControlStateNormal withURL:url];
}

- (UIButton *)avatarButton
{
    if (!_avatarButton)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button addTarget:self action:@selector(_showProfile) forControlEvents:UIControlEventTouchUpInside];
        button.clipsToBounds = YES;
        button.layer.cornerRadius = 20;
        button.backgroundColor = ClearColor;

        _avatarButton = button;
    }
    return _avatarButton;
}

- (TTTAttributedLabel *)usernameLabel
{
    if (!_usernameLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:kFontSizeCaption];
        label.backgroundColor = ClearColor;
        label.textColor = JoyyBlue;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;
        label.preferredMaxLayoutWidth = SCREEN_WIDTH - 60;

        _usernameLabel = label;
    }
    return _usernameLabel;
}

- (TTTAttributedLabel *)commentLabel
{
    if (!_commentLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:kFontSizeComment];
        label.backgroundColor = ClearColor;
        label.textColor = JoyyWhite;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;
        label.preferredMaxLayoutWidth = SCREEN_WIDTH - 60;

        _commentLabel = label;
    }
    return _commentLabel;
}

- (void)_showProfile
{

}

@end
