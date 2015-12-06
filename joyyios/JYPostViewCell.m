//
//  JYPostViewCell.m
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYComment.h"
#import "JYFriendManager.h"
#import "JYPost.h"
#import "JYPostActionView.h"
#import "JYPostCommentView.h"
#import "JYPostMediaView.h"
#import "JYPostViewCell.h"
#import "JYPosterView.h"


@interface JYPostViewCell ()
@property (nonatomic) BOOL didSetupConstraints;
@property (nonatomic) JYPostMediaView *mediaView;
@property (nonatomic) JYPostActionView *actionView;
@property (nonatomic) JYPosterView *posterView;
@property (nonatomic) JYPostCommentView *commentView;
@property (nonatomic) NSLayoutConstraint *commentViewHeightConstraint;
@property (nonatomic) TTTAttributedLabel *likesLabel;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@end


@implementation JYPostViewCell

+ (UIImage *)sharedPlaceholderImage
{
    static UIImage *_sharedPlaceholderImage = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{

        _sharedPlaceholderImage = [UIImage imageNamed:@"heart"];
    });

    return _sharedPlaceholderImage;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = JoyyWhitePure;

        [self.contentView addSubview:self.posterView];
        [self.contentView addSubview:self.mediaView];
        [self.contentView addSubview:self.actionView];
        [self.contentView addSubview:self.likesLabel];
        [self.contentView addSubview:self.commentView];

        NSDictionary *views = @{
                                @"posterView": self.posterView,
                                @"mediaView": self.mediaView,
                                @"actionView": self.actionView,
                                @"likesLabel": self.likesLabel,
                                @"commentView": self.commentView
                              };
        NSDictionary *metrics = @{
                                  @"SW":@(SCREEN_WIDTH)
                                  };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[posterView]-0-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[mediaView]-0-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[actionView]-0-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[likesLabel]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[commentView]-10-|" options:0 metrics:nil views:views]];

        NSString *format = @"V:|-0@500-[posterView(40)][mediaView(SW)][actionView(40)][likesLabel][commentView]-10@500-|";
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
    self.posterView.post = post;
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
    if (!_post)
    {
        self.likesLabel.text = nil;
        return;
    }

    NSMutableArray *likedByUsernames = [NSMutableArray new];
    for (JYComment *comment in self.post.commentList)
    {
        if ([comment isLike])
        {
            JYFriend *friend = [[JYFriendManager sharedInstance] friendOfId:comment.ownerId];
            if (friend)
            {
                [likedByUsernames addObject:friend.username];
            }
        }
    }

    if ([likedByUsernames count] == 0)
    {
        self.likesLabel.text = nil;
    }
    else
    {
        NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:likedByUsernames];
        NSArray *dedupedUsernames = [orderedSet array];
        NSString *likedList = [dedupedUsernames componentsJoinedByString:@", "];
        self.likesLabel.text = [NSString stringWithFormat:@"%@ %@", kLikeText, likedList];
    }

    self.likesLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.likesLabel.bounds);
}

- (JYPosterView *)posterView
{
    if (!_posterView)
    {
        _posterView = [[JYPosterView alloc] init];
    }
    return _posterView;
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
        _likesLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        _likesLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _likesLabel.font = [UIFont systemFontOfSize:kFontSizeComment];
        _likesLabel.backgroundColor = JoyyWhiter;
        _likesLabel.textColor = JoyyBlue;
        _likesLabel.textInsets = UIEdgeInsetsMake(0, 5, 0, 5);
        _likesLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _likesLabel.numberOfLines = 0;
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

@end
