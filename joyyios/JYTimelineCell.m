//
//  JYTimelineCell.m
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYComment.h"
#import "JYFriendManager.h"
#import "JYPost.h"
#import "JYPostActionView.h"
#import "JYPostCommentView.h"
#import "JYPostMediaView.h"
#import "JYPostOwnerView.h"
#import "JYTimelineCell.h"


@interface JYTimelineCell () <TTTAttributedLabelDelegate>
@property (nonatomic) JYPostMediaView *mediaView;
@property (nonatomic) JYPostActionView *actionView;
@property (nonatomic) JYPostOwnerView *ownerView;
@property (nonatomic) JYPostCommentView *commentView;
@property (nonatomic) NSLayoutConstraint *commentViewHeightConstraint;
@property (nonatomic) TTTAttributedLabel *likesLabel;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@end


@implementation JYTimelineCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = JoyyWhitePure;

        [self.contentView addSubview:self.ownerView];
        [self.contentView addSubview:self.mediaView];
        [self.contentView addSubview:self.actionView];
        [self.contentView addSubview:self.likesLabel];
        [self.contentView addSubview:self.commentView];

        NSDictionary *views = @{
                                @"ownerView": self.ownerView,
                                @"mediaView": self.mediaView,
                                @"actionView": self.actionView,
                                @"likesLabel": self.likesLabel,
                                @"commentView": self.commentView
                              };
        NSDictionary *metrics = @{
                                  @"SW":@(SCREEN_WIDTH)
                                  };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[ownerView]-0-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[mediaView]-0-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[actionView]-0-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[likesLabel]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[commentView]-10-|" options:0 metrics:nil views:views]];

        NSString *format = @"V:|-0@500-[ownerView(40)][mediaView(SW)][actionView(40)][likesLabel][commentView]-10@500-|";
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:views]];

        self.commentViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.commentView
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                 multiplier:0.0f
                                                                   constant:0.0f];
        [self.contentView addConstraint:self.commentViewHeightConstraint];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.post = nil;
}

- (void)setPost:(JYPost *)post
{
    _post = post;
    self.ownerView.post = post;
    self.mediaView.post = post;
    [self _updateCommentsAndLikes];
}

- (void)_updateCommentsAndLikes
{
    [self _updateLikesLabel];
    self.actionView.post = _post;

    if (_post)
    {
        self.commentView.commentList = _post.commentList;
    }
    else
    {
        self.commentView.commentList = nil;
    }

    [self.commentView reloadData];
    self.commentViewHeightConstraint.constant = self.commentView.contentSize.height;

    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}

- (void)_updateLikesLabel
{
    NSArray *usernames = [self _likedByUsernames];
    if ([usernames count] == 0)
    {
        self.likesLabel.text = nil;
        return;
    }

    NSString *likedList = [usernames componentsJoinedByString:@", "];
    self.likesLabel.text = [NSString stringWithFormat:@"%@ %@", kLikeText, likedList];

    // add link to make the label clickable on each username
    for (NSString *username in usernames)
    {
        NSRange range = [self.likesLabel.text rangeOfString:username];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat: @"username://%@", username]];
        [self.likesLabel addLinkToURL:url withRange:range];
    }

    self.likesLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.likesLabel.bounds);
}

- (NSArray *)_likedByUsernames
{
    NSMutableArray *usernames = [NSMutableArray new];

    if (!_post)
    {
        self.likesLabel.text = nil;
        return usernames;
    }

    for (JYComment *comment in self.post.commentList)
    {
        if ([comment isLike])
        {
            JYFriend *friend = [[JYFriendManager sharedInstance] friendWithId:comment.ownerId];
            if (friend)
            {
                [usernames addObject:friend.username];
            }
        }
    }

    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:usernames];
    return [orderedSet array];
}

- (JYPostOwnerView *)ownerView
{
    if (!_ownerView)
    {
        _ownerView = [[JYPostOwnerView alloc] init];
    }
    return _ownerView;
}

- (JYPostMediaView *)mediaView
{
    if (!_mediaView)
    {
        _mediaView = [[JYPostMediaView alloc] init];
    }
    return _mediaView;
}

- (UIView *)actionView
{
    if (!_actionView)
    {
        _actionView = [[JYPostActionView alloc] init];
    }
    return _actionView;
}

- (TTTAttributedLabel *)likesLabel
{
    if (!_likesLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:kFontSizeComment];
        label.backgroundColor = JoyyWhiter;
        label.textColor = JoyyBlue;
        label.textInsets = UIEdgeInsetsMake(0, 5, 0, 5);
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;
        label.delegate = self;

        label.linkAttributes = @{
                                   (NSString*)kCTForegroundColorAttributeName: (__bridge id)(JoyyBlue.CGColor),
                                   (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                               };
        label.activeLinkAttributes = @{
                                          (NSString*)kCTForegroundColorAttributeName: (__bridge id)(FlatSand.CGColor),
                                          (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                                     };
        _likesLabel = label;
    }
    return _likesLabel;
}

- (JYPostCommentView *)commentView
{
    if (!_commentView)
    {
        _commentView = [[JYPostCommentView alloc] init];
    }
    return _commentView;
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
