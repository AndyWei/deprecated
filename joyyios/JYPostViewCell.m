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
#import "JYPost.h"
#import "JYPostViewCell.h"
#import "JYPostActionView.h"
#import "JYPostCommentView.h"
#import "JYPosterView.h"


@interface JYPostViewCell ()
@property (nonatomic) BOOL didSetupConstraints;
@property (nonatomic) JYPostActionView *actionView;
@property (nonatomic) JYPosterView *posterView;
@property (nonatomic) JYPostCommentView *commentView;
@property (nonatomic) TTTAttributedLabel *captionLabel;
@property (nonatomic) TTTAttributedLabel *likesLabel;
@property (nonatomic) UIImageView *photoView;
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
        [self.contentView addSubview:self.photoView];
        [self.contentView addSubview:self.captionLabel];
        [self.contentView addSubview:self.actionView];
        [self.contentView addSubview:self.likesLabel];
        [self.contentView addSubview:self.commentView];
    }
    return self;
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
    [@[self.photoView] autoSetViewsDimension:ALDimensionHeight toSize:SCREEN_WIDTH];
    NSArray *views = @[self.posterView, self.photoView, self.actionView, self.likesLabel, self.commentView];
    [views autoSetViewsDimension:ALDimensionWidth toSize:SCREEN_WIDTH];

    // layout
    [[views firstObject] autoPinEdgeToSuperviewEdge:ALEdgeTop];
    UIView *previousView = nil;
    for (UIView *view in views) {
        if (previousView) {
            [view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousView withOffset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        }
        previousView = view;
    }
    [[views lastObject] autoPinEdgeToSuperviewEdge:ALEdgeBottom];

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

    _post = post;
    self.posterView.post = post;
    self.actionView.post = post;
    self.commentView.commentList = post.commentList;

    [self _updatePhoto];
    [self _updateCaption];
}

- (void)_updatePhoto
{
    // Fetch network image
    NSURL *url = [NSURL URLWithString:_post.URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.photoView setImageWithURLRequest:request
                          placeholderImage:nil
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
         weakSelf.photoView.image = image;
         weakSelf.photoView.alpha = 0;
         [UIView animateWithDuration:0.5 animations:^{
             weakSelf.photoView.alpha = 1;
         }];
     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
         NSLog(@"setImageWithURLRequest response = %@", response);
     }];
}

- (void)_updateCaption
{
    self.captionLabel.text = self.post.caption;
    self.captionLabel.width = SCREEN_WIDTH;
    self.captionLabel.preferredMaxLayoutWidth = SCREEN_WIDTH - kMarginLeft - kMarginRight;
    self.captionLabel.textInsets = UIEdgeInsetsMake(0, kMarginLeft, 0, kMarginRight);

    [self.captionLabel sizeToFit];
    self.captionLabel.centerX = self.centerX;
    self.captionLabel.y = SCREEN_WIDTH - self.captionLabel.height - 10;
}

- (JYPosterView *)posterView
{
    if (!_posterView)
    {
        _posterView = [JYPosterView newAutoLayoutView];
    }
    return _posterView;
}

- (UIImageView *)photoView
{
    if (!_photoView)
    {
        _photoView = [UIImageView newAutoLayoutView];
        _photoView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _photoView;
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
        _likesLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0)];
        [_likesLabel configureForAutoLayout];
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

- (TTTAttributedLabel *)captionLabel
{
    if (!_captionLabel)
    {
        CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, 0);
        _captionLabel = [[TTTAttributedLabel alloc] initWithFrame:frame];
        _captionLabel.backgroundColor = JoyyBlack80;
        _captionLabel.textColor = JoyyWhite;
        _captionLabel.font = [UIFont systemFontOfSize:kFontSizeCaption];
        _captionLabel.textAlignment = NSTextAlignmentCenter;

        _captionLabel.layer.cornerRadius = 4;
        _captionLabel.clipsToBounds = YES;
    }
    return _captionLabel;
}

//- (void)_showAllComments
//{
//    NSDictionary *info = @{@"post": self.post, @"edit":@(NO)};
//    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWillCommentPost object:nil userInfo:info];
//}

@end
