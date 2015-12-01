//
//  JYPostViewCell.m
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <KVOController/FBKVOController.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYComment.h"
#import "JYFriendManager.h"
#import "JYMediaView.h"
#import "JYPost.h"
#import "JYPostViewCell.h"
#import "JYPostActionView.h"
#import "JYPostCommentView.h"
#import "JYPosterView.h"


@interface JYPostViewCell ()
@property (nonatomic) BOOL didSetupConstraints;
@property (nonatomic) FBKVOController *observer;
@property (nonatomic) JYMediaView *mediaView;
@property (nonatomic) JYPostActionView *actionView;
@property (nonatomic) JYPosterView *posterView;
@property (nonatomic) JYPostCommentView *commentView;
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
    }
    return self;
}

- (void)dealloc
{
    [self.observer unobserveAll];
    self.observer = nil;
}

- (void)_startObserve:(JYPost *)post
{
    __weak typeof(self) weakSelf = self;

    [self.observer observe:post keyPath:@"commentList" options:NSKeyValueObservingOptionNew block:^(JYPostViewCell *cell, JYPost *post, NSDictionary *change) {

          [weakSelf _updateCommentsAndLikes];
    }];
}

- (void)_stopObserve:(JYPost *)post
{
    [self.observer unobserve:post];
}

- (void)updateConstraints
{
    if (self.didSetupConstraints)
    {
        [super updateConstraints];
        return;
    }

    self.contentView.bounds = CGRectMake(0.0f, 0.0f, 99999.0f, 99999.0f);

    // size
    [@[self.posterView, self.actionView] autoSetViewsDimension:ALDimensionHeight toSize:40];
    [@[self.mediaView] autoSetViewsDimension:ALDimensionHeight toSize:SCREEN_WIDTH];

    NSArray *views = @[self.posterView, self.mediaView, self.actionView, self.likesLabel, self.commentView];

    // layout
    [[views firstObject] autoPinEdgeToSuperviewEdge:ALEdgeTop];
    UIView *previousView = nil;
    for (UIView *view in views)
    {
        [view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [view autoPinEdgeToSuperviewEdge:ALEdgeRight];

        if (previousView)
        {
            [view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousView withOffset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        }
        previousView = view;
    }
    [[views lastObject] autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.contentView withOffset:0.5 relation:NSLayoutRelationGreaterThanOrEqual];

//    [self.posterView autoPinEdgeToSuperviewEdge:ALEdgeTop];
//    [self.mediaView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.posterView withOffset:0 relation:NSLayoutRelationEqual];
//    [self.actionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.mediaView withOffset:0 relation:NSLayoutRelationEqual];
//    [self.likesLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.actionView withOffset:0 relation:NSLayoutRelationEqual];
//    [self.commentView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.likesLabel withOffset:0 relation:NSLayoutRelationEqual];
//    [self.commentView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.contentView withOffset:0.5 relation:NSLayoutRelationGreaterThanOrEqual];

    self.didSetupConstraints = YES;
    [super updateConstraints];
}

- (void)setPost:(JYPost *)post
{
    if (!post)
    {
        NSAssert(NO, @"post should not be nil");
        return;
    }

    if (_post == post)
    {
        return;
    }

    if (_post)
    {
        [self _stopObserve:_post];
    }

    _post = post;
    self.posterView.post = post;
    self.mediaView.post = post;
    self.actionView.post = post;
    [self _updateLikesLabel];
    self.commentView.commentList = post.commentList;

    [self _startObserve:post];
}

- (void)_updateCommentsAndLikes
{
    [self _updateLikesLabel];
    self.commentView.commentList = self.post.commentList;
}

- (void)_updateLikesLabel
{
    NSMutableArray *likedByUsernames = [NSMutableArray new];
    for (JYComment *comment in self.post.commentList)
    {
        if ([kLikeText isEqualToString:comment.content])
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
        NSString *likedList = [likedByUsernames componentsJoinedByString:@", "];
        self.likesLabel.text = [NSString stringWithFormat:@"%@ %@", kLikeText, likedList];
    }
}

- (JYPosterView *)posterView
{
    if (!_posterView)
    {
        _posterView = [JYPosterView newAutoLayoutView];
    }
    return _posterView;
}

- (JYMediaView *)mediaView
{
    if (!_mediaView)
    {
        _mediaView = [JYMediaView newAutoLayoutView];
    }
    return _mediaView;
}

- (UIView *)actionView
{
    if (!_actionView)
    {
        _actionView = [JYPostActionView newAutoLayoutView];
    }
    return _actionView;
}

- (TTTAttributedLabel *)likesLabel
{
    if (!_likesLabel)
    {
        _likesLabel = [TTTAttributedLabel newAutoLayoutView];
        _likesLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
        _likesLabel.backgroundColor = FlatBlue;
        _likesLabel.textColor = JoyyBlue;
    }
    return _likesLabel;
}

- (JYPostCommentView *)commentView
{
    if (!_commentView)
    {
        _commentView = [JYPostCommentView newAutoLayoutView];
    }
    return _commentView;
}

- (FBKVOController *)observer
{
    if (!_observer)
    {
        _observer = [FBKVOController controllerWithObserver:self];
    }
    return _observer;
}

//- (void)_showAllComments
//{
//    NSDictionary *info = @{@"post": self.post, @"edit":@(NO)};
//    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWillCommentPost object:nil userInfo:info];
//}

@end
