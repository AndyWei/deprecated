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
@end

@implementation JYMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = JoyyWhite;

        [self.contentView addSubview:self.avatarView];
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

- (void)setMessage:(JYMessage *)message
{
    _message = message;
    [self _fetchAvatarImage];
}

- (void)_fetchAvatarImage
{
    JYFriend *friend = [_message isOutgoing].boolValue? [JYFriend myself]: [[JYFriendManager sharedInstance] friendWithId:self.message.peerId];
    NSURL *avatarURL = friend.avatarThumbnailURL;
    [self.avatarView sd_setImageWithURL:avatarURL];
}

@end
