//
//  JYNewCommentCell.m
//  joyyios
//
//  Created by Ping Yang on 12/14/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYButton.h"
#import "JYComment.h"
#import "JYFriendManager.h"
#import "JYLocalDataManager.h"
#import "JYPost.h"
#import "JYNewCommentCell.h"
#import "NSDate+Joyy.h"

@interface JYNewCommentCell ()
@property(nonatomic) TTTAttributedLabel *commentLabel;
@property(nonatomic) TTTAttributedLabel *timeLabel;
@property(nonatomic) TTTAttributedLabel *usernameLabel;
@property(nonatomic) UIImageView *avatarView;
@property(nonatomic) UIImageView *postImageView;
@end

@implementation JYNewCommentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = JoyyWhitePure;

        [self.contentView addSubview:self.avatarView];
        [self.contentView addSubview:self.commentLabel];
        [self.contentView addSubview:self.timeLabel];
        [self.contentView addSubview:self.usernameLabel];
        [self.contentView addSubview:self.postImageView];

        NSDictionary *views = @{
                                @"avatarView": self.avatarView,
                                @"commentLabel": self.commentLabel,
                                @"timeLabel": self.timeLabel,
                                @"usernameLabel": self.usernameLabel,
                                @"postImageView": self.postImageView
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarView(40)]-10-[usernameLabel]-[postImageView(60)]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarView(40)]-10-[commentLabel]-[postImageView(60)]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarView(40)]-10-[timeLabel]-[postImageView(60)]-10-|" options:0 metrics:nil views:views]];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[avatarView(40)]-(>=10@500)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[postImageView(60)]-(>=10@500)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[usernameLabel(20)][commentLabel][timeLabel(20)]-(>=10@500)-|" options:0 metrics:nil views:views]];
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
        self.avatarView.image = nil;
        self.postImageView.image = nil;
        self.commentLabel.text = nil;
        self.timeLabel.text = nil;
        self.usernameLabel.text = nil;
        return;
    }

    _comment = comment;

    [self _updateUsernameLabel];
    [self _updateCommentLabel];
    [self _updateTimeLabel];
    [self _updateAvatarView];
    [self _updatePostImageView];
}

- (void)_updateTimeLabel
{
    NSDate *date = [NSDate dateOfId:_comment.commentId];
    self.timeLabel.text = [date localeStringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
}

- (void)_updateUsernameLabel
{
    JYFriend *owner = [[JYFriendManager sharedInstance] friendWithId:_comment.ownerId];
    self.usernameLabel.text = owner.username;
}

- (void)_updateCommentLabel
{
    JYFriend *replyTo = ([_comment.replyToId unsignedLongLongValue] == 0) ? nil: [[JYFriendManager sharedInstance] friendWithId:_comment.replyToId];
    NSString *replyText = NSLocalizedString(@"reply", nil);
    if (replyTo)
    {
        self.commentLabel.text = [NSString stringWithFormat:@"%@ %@: %@", replyText, replyTo.username, _comment.content];
    }
    else
    {
        self.commentLabel.text = _comment.content;
    }
}

- (void)_updateAvatarView
{
    JYFriend *owner = [[JYFriendManager sharedInstance] friendWithId:_comment.ownerId];
    if (!owner)
    {
        self.avatarView.image = nil;
        return;
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:owner.avatarThumbnailURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.avatarView setImageWithURLRequest:request
                          placeholderImage:owner.avatarImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       weakSelf.avatarView.image = image;
                                       owner.avatarImage = image;
                                   } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                       NSLog(@"setImageWithURLRequest failed with error = %@", error);
                                   }];
}

- (void)_updatePostImageView
{
    JYPost *post = [[JYLocalDataManager sharedInstance] selectPostWithId:_comment.postId];
    if (!post)
    {
        self.postImageView.image = nil;
        return;
    }

    NSURL *url = [NSURL URLWithString:post.URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.postImageView setImageWithURLRequest:request
                              placeholderImage:nil
                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                        weakSelf.postImageView.image = image;
                                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                        NSLog(@"setImageWithURLRequest failed with error = %@", error);
                                    }];
}

- (TTTAttributedLabel *)_createLabel
{
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont systemFontOfSize:kFontSizeComment];
    label.backgroundColor = ClearColor;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.preferredMaxLayoutWidth = SCREEN_WIDTH - 140;

    return label;
}

- (UIImageView *)avatarView
{
    if (!_avatarView)
    {
        _avatarView = [[UIImageView alloc] init];
        _avatarView.translatesAutoresizingMaskIntoConstraints = NO;
        _avatarView.contentMode = UIViewContentModeScaleAspectFit;
        _avatarView.layer.cornerRadius = 20;
        _avatarView.layer.masksToBounds = YES;
    }
    return _avatarView;
}

- (UIImageView *)postImageView
{
    if (!_postImageView)
    {
        _postImageView = [[UIImageView alloc] init];
        _postImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _postImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _postImageView;
}

- (TTTAttributedLabel *)commentLabel
{
    if (!_commentLabel)
    {
        _commentLabel = [self _createLabel];
        _commentLabel.textColor = JoyyBlack;
    }
    return _commentLabel;
}

- (TTTAttributedLabel *)timeLabel
{
    if (!_timeLabel)
    {
        _timeLabel = [self _createLabel];
        _timeLabel.textColor = JoyyGray;
        _timeLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
    }
    return _timeLabel;
}

- (TTTAttributedLabel *)usernameLabel
{
    if (!_usernameLabel)
    {
        _usernameLabel = [self _createLabel];
        _usernameLabel.textColor = JoyyBlue;
        _usernameLabel.font = [UIFont systemFontOfSize:kFontSizeCaption];
    }
    return _usernameLabel;
}

@end
