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
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = JoyyBlack50;

        [self.contentView addSubview:self.avatarView];
        [self.contentView addSubview:self.commentLabel];

        NSDictionary *views = @{
                                @"avatarView": self.avatarView,
                                @"commentLabel": self.commentLabel
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[avatarView(40)]-10-[commentLabel]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[avatarView(40)]-10@500-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[commentLabel(>=40@500)]-10-|" options:0 metrics:nil views:views]];
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
    self.commentLabel.text = comment.displayText;
    self.commentLabel.preferredMaxLayoutWidth = SCREEN_WIDTH - 90;
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
    if (!_avatarView)
    {
        UIImageView *view = [[UIImageView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.contentMode = UIViewContentModeScaleAspectFit;
        view.layer.cornerRadius = 20;
        view.layer.masksToBounds = YES;
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
        label.backgroundColor = ClearColor;
        label.textColor = JoyyWhite;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;

        _commentLabel = label;
    }
    return _commentLabel;
}

@end
