//
//  JYCommentViewCell.m
//  joyyios
//
//  Created by Ping Yang on 5/14/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYCommentViewCell.h"
#import "JYFriendManager.h"

@interface JYCommentViewCell ()
@property(nonatomic) TTTAttributedLabel *commentLabel;
@property(nonatomic) UIImageView *avatarView;
@end

@implementation JYCommentViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = JoyyBlack50;

        [self.contentView addSubview:self.avatarView];
        [self.contentView addSubview:self.commentLabel];

        NSDictionary *views = @{
                                @"avatarView": self.avatarView,
                                @"commentLabel": self.commentLabel
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[avatarView(40)]-10-[commentLabel]-20|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[avatarView(40)]-(>=10)-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[commentLabel]-(>=10)-|" options:0 metrics:nil views:views]];
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
        self.avatarView.backgroundColor = ClearColor;
        self.commentLabel.text = nil;
        return;
    }

    _comment = comment;
    self.commentLabel.text = comment.content;
    [self _updateAvatarView];
}

- (void)_updateAvatarView
{
    JYFriend *friend = [[JYFriendManager sharedInstance] friendOfId:self.comment.ownerId];
    NSURL *url = [NSURL URLWithString:friend.avatarURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.avatarView setImageWithURLRequest:request
                                       placeholderImage:nil
                                                success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                    weakSelf.avatarView.image = image;

                                                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                    NSLog(@"comment owner avatar view image failed with error = %@", error);
                                                }];
}

- (UIImageView *)avatarView
{
    if (_avatarView)
    {
        UIImageView *view = [[UIImageView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.contentMode = UIViewContentModeScaleAspectFit;
        _avatarView = view;
    }
    return _avatarView;
}

- (TTTAttributedLabel *)commentLabel
{
    if (!_commentLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:kFontSizeComment];
        label.textInsets = UIEdgeInsetsMake(0, 20, 0, kMarginRight);
        label.backgroundColor = ClearColor;
        label.textColor = JoyyWhite;
        _commentLabel = label;
    }
    return _commentLabel;
}

@end
