//
//  JYMessageCell.m
//  joyyios
//
//  Created by Ping Yang on 2/15/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>

#import "JYFriendManager.h"
#import "JYMessageCell.h"

@interface JYMessageCell ()
@property (nonatomic) NSLayoutConstraint *topLabelVConstraint;
@end

@implementation JYMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = JoyyWhiter;

        [self.contentView addSubview:self.avatarView];
        [self.contentView addSubview:self.topLabel];

        NSLayoutConstraint *topLabelHConstraint = [NSLayoutConstraint constraintWithItem:self.topLabel
                                                                              attribute:NSLayoutAttributeCenterX
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:self.contentView
                                                                              attribute:NSLayoutAttributeCenterX
                                                                             multiplier:1.0f
                                                                               constant:0.0f];

        self.topLabelVConstraint = [NSLayoutConstraint constraintWithItem:self.topLabel
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0f
                                                                 constant:0.0f];
         [self.contentView addConstraint:topLabelHConstraint];
         [self.contentView addConstraint:self.topLabelVConstraint];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    _message = nil;

    self.avatarView.image = nil;
}

- (UIImageView *)avatarView
{
    if (!_avatarView)
    {
        _avatarView = [UIImageView new];
        _avatarView.translatesAutoresizingMaskIntoConstraints = NO;
        _avatarView.contentMode = UIViewContentModeScaleAspectFit;
        _avatarView.layer.cornerRadius = 35.0f/2.0f;
        _avatarView.layer.masksToBounds = YES;
    }
    return _avatarView;
}

- (TTTAttributedLabel *)topLabel
{
    if (!_topLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:14];
        label.textInsets = UIEdgeInsetsMake(0, 3, 0, 3);
        label.backgroundColor = JoyyWhite;
        label.textColor = JoyyWhiter;
        label.layer.cornerRadius = 4.0f;
        label.layer.masksToBounds = YES;
        label.preferredMaxLayoutWidth = 200;
        _topLabel = label;
    }
    return _topLabel;
}

- (void)setMessage:(JYMessage *)message
{
    _message = message;
    [self _fetchAvatarImage];
}

- (void)setTopLabelText:(NSString *)topLabelText
{
    _topLabelText = topLabelText;
    self.topLabel.text = topLabelText;
    [self.topLabel sizeToFit];

    if (topLabelText)
    {
        self.topLabelVConstraint.constant = 20.0f;
    }
    else
    {
        self.topLabelVConstraint.constant = 0.0f;
    }
}

- (void)_fetchAvatarImage
{
    JYFriend *friend = [_message isOutgoing].boolValue? [JYFriend myself]: [[JYFriendManager sharedInstance] friendWithId:self.message.peerId];
    NSURL *avatarURL = friend.avatarThumbnailURL;
    [self.avatarView sd_setImageWithURL:avatarURL];
}

@end
