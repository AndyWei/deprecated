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

#import "JYAvatar.h"
#import "JYButton.h"
#import "JYComment.h"
#import "JYLocalDataManager.h"
#import "JYPost.h"
#import "JYPostViewCell.h"
#import "NSDate+Joyy.h"

static const CGFloat kPosterBarHeight = 40;
static const CGFloat kActionBarHeight = 40;
static const CGFloat kButtonWidth = kActionBarHeight;
static const CGFloat kButtonDistance = 20;
static const CGFloat kPostTimeLabelWidth = 50;

@interface JYPostViewCell () <TTTAttributedLabelDelegate>
@property(nonatomic) BOOL likeButtonPressed;
@property(nonatomic) FBKVOController *observer;
@property(nonatomic) JYButton *avatarButton;
@property(nonatomic) JYButton *commentButton;
@property(nonatomic) JYButton *likeButton;
@property(nonatomic) TTTAttributedLabel *captionLabel;
@property(nonatomic) TTTAttributedLabel *likesLabel;
@property(nonatomic) TTTAttributedLabel *posterNameLabel;
@property(nonatomic) TTTAttributedLabel *postTimeLabel;
@property(nonatomic) UIImageView *photoView;
@property(nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property(nonatomic) UIView *actionBar;
@property(nonatomic) UIView *posterBar;
@property(nonatomic) NSMutableArray *commentLabels;
@end


@implementation JYPostViewCell

+ (CGFloat)labelHeightForText:(NSString *)text withFontSize:(CGFloat)fontSize textAlignment:(NSTextAlignment)textAlignment andWidth:(CGFloat)width
{
    CGSize maximumSize = CGSizeMake(width, MAXFLOAT);

    static TTTAttributedLabel *dummyLabel = nil;
    if (!dummyLabel)
    {
        dummyLabel = [TTTAttributedLabel new];
        dummyLabel.numberOfLines = 0;
        dummyLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    dummyLabel.font = [UIFont systemFontOfSize:fontSize];
    dummyLabel.textAlignment = textAlignment;
    dummyLabel.text = text;

    CGSize expectSize = [dummyLabel sizeThatFits:maximumSize];
    CGFloat labelHeight = expectSize.height;

    return labelHeight;
}

+ (CGFloat)heightForPost:(JYPost *)post;
{
    CGFloat imageHeight = SCREEN_WIDTH;

    CGFloat commentsHeight = 0;
    for (JYComment *comment in post.commentList)
    {
        NSString *text = comment.displayText;
        CGFloat height = [JYPostViewCell labelHeightForText:text withFontSize:kFontSizeComment textAlignment:NSTextAlignmentLeft andWidth:[JYPostViewCell textAreaWidth]];
        commentsHeight += (height + 5);
    }

    return imageHeight + commentsHeight + kActionBarHeight + kPosterBarHeight;
}

+ (CGFloat)textAreaWidth
{
    return (SCREEN_WIDTH - kMarginLeft - kMarginRight);
}

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
        self.opaque = YES;
        self.backgroundColor = JoyyBlack;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)dealloc
{
    [self.observer unobserveAll];
    self.observer = nil;
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
    [self _updateImage];
    [self _updatePosterBar];
    [self _updateActionBar];
    [self _updateCaption];
    [self _updateComments];
    [self _startObserve:_post];
}

- (void)_startObserve:(JYPost *)post
{
    __weak typeof(self) weakSelf = self;
    [self.observer observe:post keyPath:@"isLiked" options:NSKeyValueObservingOptionNew block:^(JYPostViewCell *cell, JYPost *post, NSDictionary *change) {

        [weakSelf _updateLikeButtonImage];
    }];

    [self.observer observe:post keyPath:@"likeCount" options:NSKeyValueObservingOptionNew block:^(JYPostViewCell *cell, JYPost *post, NSDictionary *change) {

//        [weakSelf _updateLikeCount];
    }];

    [self.observer observe:post keyPath:@"commentCount" options:NSKeyValueObservingOptionNew block:^(JYPostViewCell *cell, JYPost *post, NSDictionary *change) {

//        [weakSelf _updateCommentCount];
    }];
}

- (void)_stopObserve:(JYPost *)post
{
    [self.observer unobserve:post];
}

- (void)_updateImage
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

- (void)_updatePosterBar
{
    [self _updateAvatarButtonImage];
    [self _updatePosterName];
    [self _updatePostTime];
}

- (void)_updateAvatarButtonImage
{
    JYUser *owner = [[JYLocalDataManager sharedInstance] userOfId:self.post.ownerId];
    NSURL *url = [NSURL URLWithString:owner.avatarURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.avatarButton.imageView setImageWithURLRequest:request
                          placeholderImage:nil
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       weakSelf.avatarButton.imageView.image = image;

                                   } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                       NSLog(@"setImageWithURLRequest failed with response = %@", response);
                                   }];
}

- (void)_updatePosterName
{
    self.posterNameLabel.text = [[JYDataStore sharedInstance] usernameOfId:self.post.ownerId];
}

- (void)_updatePostTime
{
    NSDate *date = [NSDate dateOfId:self.post.postId];
    self.postTimeLabel.text = [date ageString];
}

- (void)_updateActionBar
{
    _likeButtonPressed = NO;

    [self _updateLikeButtonImage];
//    [self _updateLikeCount];
//    [self _updateCommentCount];
}

- (void)_updateLikeButtonImage
{
    if (self.post.isLiked)
    {
        self.likeButton.imageView.image = [UIImage imageNamed:@"heart_selected"];
        self.likeButton.contentColor = JoyyBlue;
    }
    else
    {
        self.likeButton.imageView.image = [UIImage imageNamed:@"heart"];
        self.likeButton.contentColor = JoyyGray;
    }
}

- (void)_updateLikes
{
//    NSString *likes = NSLocalizedString(@"likes", nil);
//    self.likeCountLabel.text = [NSString stringWithFormat:@"%tu %@   ·", self.post.likeCount, likes];
}

- (void)_updateCaption
{
    self.captionLabel.text = self.post.caption;
    self.captionLabel.width = SCREEN_WIDTH;
    self.captionLabel.preferredMaxLayoutWidth = [[self class] textAreaWidth];
    self.captionLabel.textInsets = UIEdgeInsetsMake(0, kMarginLeft, 0, kMarginRight);

    [self.captionLabel sizeToFit];
    self.captionLabel.centerX = self.centerX;
    self.captionLabel.y = SCREEN_WIDTH - self.captionLabel.height - 10;
}

- (void)_updateComments
{
    [self _resetCommentlabels];

    CGFloat y = CGRectGetMaxY(self.actionBar.frame);
    for (JYComment *comment in self.post.commentList)
    {
        TTTAttributedLabel *label = [self _createCommentLabel];
        [self.commentLabels addObject:label];
        [self addSubview:label];

        NSString *text = comment.displayText;
        label.text = text;

        CGFloat height = [JYPostViewCell labelHeightForText:text withFontSize:kFontSizeComment textAlignment:NSTextAlignmentLeft andWidth:label.width];
        label.height = height + 5;
        label.y = y;
        y = CGRectGetMaxY(label.frame);
    }
}

- (void)_resetCommentlabels
{
    for (TTTAttributedLabel *label in self.commentLabels)
    {
        [label removeFromSuperview];
    }

    self.commentLabels = [NSMutableArray new];
}

- (FBKVOController *)observer
{
    if (!_observer)
    {
        _observer = [FBKVOController controllerWithObserver:self];
    }
    return _observer;
}

- (UIView *)posterBar
{
    if (!_posterBar)
    {
        _posterBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, kPosterBarHeight)];
        _posterBar.opaque = YES;
        _posterBar.backgroundColor = JoyyWhitePure;

        [_posterBar addSubview:self.avatarButton];
        [_posterBar addSubview:self.posterNameLabel];
        [_posterBar addSubview:self.postTimeLabel];

        [self addSubview:_posterBar];
    }
    return _posterBar;
}

- (JYButton *)avatarButton
{
    if (!_avatarButton)
    {
        CGRect frame = CGRectMake(kMarginLeft, 0, kButtonWidth, kActionBarHeight);
        JYButton *button = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleCentralImage shouldMaskImage:NO];
        button.imageView.image = [UIImage imageNamed:@"wink"];
        button.contentAnimateToColor = JoyyBlue;
        button.foregroundColor = ClearColor;
        button.cornerRadius = kButtonWidth/2;
        _avatarButton = button;
        [_avatarButton addTarget:self action:@selector(_showProfile) forControlEvents:UIControlEventTouchUpInside];
    }
    return _avatarButton;
}

- (TTTAttributedLabel *)posterNameLabel
{
    if (!_posterNameLabel)
    {
        CGFloat x = CGRectGetMaxX(self.avatarButton.frame) + kMarginLeft;
        CGFloat width = CGRectGetMinX(self.postTimeLabel.frame) - kMarginRight;
        CGRect frame = CGRectMake(x, 0, width, kPosterBarHeight);
        _posterNameLabel = [self _createLabelWithFrame:frame];
        _posterNameLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
        _posterNameLabel.textColor = JoyyBlue;
    }
    return _posterNameLabel;
}

- (TTTAttributedLabel *)postTimeLabel
{
    if (!_postTimeLabel)
    {
        CGFloat x = SCREEN_WIDTH - kPostTimeLabelWidth;
        CGRect frame = CGRectMake(x, 0, kPostTimeLabelWidth, kPosterBarHeight);
        _postTimeLabel = [self _createLabelWithFrame:frame];
        _postTimeLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
        _postTimeLabel.textColor = JoyyGray;
    }
    return _postTimeLabel;
}

- (UIImageView *)photoView
{
    if (!_photoView)
    {
        CGFloat y = CGRectGetMaxY(self.posterBar.frame);
        _photoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, y, SCREEN_WIDTH, SCREEN_WIDTH)];
        _photoView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_photoView];
    }
    return _photoView;
}

- (UIView *)actionBar
{
    if (!_actionBar)
    {
        CGFloat y = CGRectGetMaxY(self.photoView.frame);
        _actionBar = [[UIView alloc] initWithFrame:CGRectMake(0, y, SCREEN_WIDTH, kActionBarHeight)];
        _actionBar.opaque = YES;
        _actionBar.backgroundColor = JoyyWhitePure;

        [_actionBar addSubview:self.likeButton];
        self.likeButton.x =  SCREEN_WIDTH - 2 * kButtonWidth - 2 * kButtonDistance;

        [_actionBar addSubview:self.commentButton];
        self.commentButton.x = CGRectGetMaxX(self.likeButton.frame) + kButtonDistance;
        self.commentButton.y += 1; // The icon is a little bit higher than the like button, add some offset to adjust

        [self addSubview:_actionBar];
    }
    return _actionBar;
}

- (TTTAttributedLabel *)likesLabel
{
    if (!_likesLabel)
    {
        CGRect frame = CGRectMake(kMarginLeft, 0, [[self class] textAreaWidth], kActionBarHeight);
        _likesLabel = [self _createLabelWithFrame:frame];
        _likesLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
        _likesLabel.backgroundColor = JoyyWhite;
        _likesLabel.textColor = JoyyBlue;
    }
    return _likesLabel;
}

- (void)_showAllComments
{
    NSDictionary *info = @{@"post": self.post, @"edit":@(NO)};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWillCommentPost object:nil userInfo:info];
}

- (void)_showProfile
{

}

- (JYButton *)commentButton
{
    if (!_commentButton)
    {
        _commentButton = [self _createButtonWithImage:[UIImage imageNamed:@"comment"]];
        [_commentButton addTarget:self action:@selector(_comment) forControlEvents:UIControlEventTouchUpInside];
    }
    return _commentButton;
}

- (void)_comment
{
    NSDictionary *info = @{@"post": self.post, @"edit":@(YES)};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWillCommentPost object:nil userInfo:info];
}

- (JYButton *)likeButton
{
    if (!_likeButton)
    {
        _likeButton = [self _createButtonWithImage:[UIImage imageNamed:@"heart"]];
        [_likeButton addTarget:self action:@selector(_like) forControlEvents:UIControlEventTouchUpInside];
    }
    return _likeButton;
}

- (void)_like
{
    if (!self.post || self.post.isLiked || self.likeButtonPressed)
    {
        return;
    }

    self.likeButtonPressed = YES;

    NSDictionary *info = @{@"post": self.post};
   [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWillLikePost object:nil userInfo:info];
}

- (TTTAttributedLabel *)captionLabel
{
    if (!_captionLabel)
    {
        CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, 0);
        _captionLabel = [self _createLabelWithFrame:frame];
        _captionLabel.backgroundColor = JoyyBlack80;
        _captionLabel.font = [UIFont systemFontOfSize:kFontSizeCaption];
        _captionLabel.textAlignment = NSTextAlignmentCenter;

        _captionLabel.layer.cornerRadius = 4;
        _captionLabel.clipsToBounds = YES;
        [self addSubview:_captionLabel];
    }
    return _captionLabel;
}

- (TTTAttributedLabel *)_createCommentLabel
{
    CGRect frame = CGRectMake(kMarginLeft, 0, [[self class] textAreaWidth], 0);
    TTTAttributedLabel *label = [self _createLabelWithFrame:frame];
    label.font = [UIFont systemFontOfSize:kFontSizeComment];
    label.backgroundColor = JoyyWhite;
    return label;
}

- (TTTAttributedLabel *)_createLabelWithFrame:(CGRect)frame
{
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
    label.delegate = self;
    label.backgroundColor = JoyyWhitePure;
    label.textColor = JoyyBlack;
    label.textAlignment = NSTextAlignmentLeft;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;

    return label;
}

- (JYButton *)_createButtonWithImage:(UIImage *)image
{
    CGRect frame = CGRectMake(0, 0, kButtonWidth, kActionBarHeight);
    JYButton *button = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
    button.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    button.imageView.image = image;
    button.contentColor = JoyyGray;
    button.contentAnimateToColor = JoyyBlue;
    button.foregroundColor = ClearColor;

    return button;
}

@end
