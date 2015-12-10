//
//  JYPostCommentCell.m
//  joyyios
//
//  Created by Ping Yang on 12/5/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYFriendManager.h"
#import "JYPostCommentCell.h"

@interface JYPostCommentCell () <TTTAttributedLabelDelegate>
@property(nonatomic) TTTAttributedLabel *commentLabel;
@end

@implementation JYPostCommentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = JoyyWhiter;

        [self.contentView addSubview:self.commentLabel];

        NSDictionary *views = @{
                                @"commentLabel": self.commentLabel
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[commentLabel]|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[commentLabel]-0-|" options:0 metrics:nil views:views]];
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
        self.commentLabel.text = nil;
        return;
    }

    _comment = comment;

    JYFriend *owner = [[JYFriendManager sharedInstance] friendWithId:comment.ownerId];
    JYFriend *replyTo = ([comment.replyToId unsignedLongLongValue] == 0) ? nil: [[JYFriendManager sharedInstance] friendWithId:comment.replyToId];
    NSString *replyText = NSLocalizedString(@"reply", nil);
    if (replyTo)
    {
        self.commentLabel.text = [NSString stringWithFormat:@"%@ %@ %@: %@", owner.username, replyText, replyTo.username, comment.content];

        [self _addLinkOnUsername:owner.username];
        [self _addLinkOnUsername:replyTo.username];
    }
    else
    {
        self.commentLabel.text = [NSString stringWithFormat:@"%@: %@", owner.username, comment.content];
        [self _addLinkOnUsername:owner.username];
    }
}

- (void)_addLinkOnUsername:(NSString *)username
{
    NSRange range = [self.commentLabel.text rangeOfString:username];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat: @"username://%@", username]];
    [self.commentLabel addLinkToURL:url withRange:range];
}

- (TTTAttributedLabel *)commentLabel
{
    if (!_commentLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:kFontSizeComment];
        label.backgroundColor = ClearColor;
        label.textColor = JoyyBlack;
        label.textInsets = UIEdgeInsetsMake(0, 5, 0, 5);
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;
        label.preferredMaxLayoutWidth = SCREEN_WIDTH - 30;
        label.delegate = self;
        label.linkAttributes = @{
                                 (NSString*)kCTForegroundColorAttributeName: (__bridge id)(JoyyBlue.CGColor),
                                 (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                                 };
        label.activeLinkAttributes = @{
                                       (NSString*)kCTForegroundColorAttributeName: (__bridge id)(FlatSand.CGColor),
                                       (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                                       };
        _commentLabel = label;
    }
    return _commentLabel;
}

#pragma mark -- TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if (![url.scheme isEqualToString:@"username"])
    {
        return;
    }

    NSString *username = url.host;
    NSAssert(username, @"username should not be nil");
    JYFriend *friend = [[JYFriendManager sharedInstance] friendWithUsername:username];
    NSAssert(friend, @"user should not be nil");
    if (friend)
    {
        NSDictionary *info = @{@"userid": friend.userId};
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidTapOnUser object:nil userInfo:info];
    }
}

@end
