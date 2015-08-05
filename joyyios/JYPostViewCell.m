//
//  JYPostViewCell.m
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <KVOController/FBKVOController.h>

#import "JYButton.h"
#import "JYPost.h"
#import "JYPostViewCell.h"

static const CGFloat kButtonWidth = 40;
static const CGFloat kButtonDistance = 20;
static const CGFloat kLikeCountLabelWidth = 80;
static const CGFloat kCommentCountButtonWidth = 100;

@interface JYPostViewCell ()

@property(nonatomic) UIImageView *photoView;
@property(nonatomic) UILabel *captionLabel;

@property(nonatomic) UIView *actionBar;
@property(nonatomic) UILabel *likeCountLabel;

@property(nonatomic) JYButton *likeButton;
@property(nonatomic) JYButton *commentButton;
@property(nonatomic) JYButton *commentCountButton;

@property(nonatomic) NSMutableArray *commentLabels;
@property(nonatomic) BOOL likeButtonPressed;

@property(nonatomic) FBKVOController *observer;

@end


@implementation JYPostViewCell

+ (CGFloat)labelHeightForText:(NSString *)text withFontSize:(CGFloat)fontSize textAlignment:(NSTextAlignment)textAlignment andWidth:(CGFloat)width
{
    CGSize maximumSize = CGSizeMake(width, MAXFLOAT);

    static UILabel *dummyLabel = nil;
    if (!dummyLabel)
    {
        dummyLabel = [UILabel new];
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
    CGFloat labelWidth = SCREEN_WIDTH - kMarginLeft - kMarginRight;
    for (NSString *text in post.commentList)
    {
        CGFloat height = [JYPostViewCell labelHeightForText:text withFontSize:kFontSizeComment textAlignment:NSTextAlignmentLeft andWidth:labelWidth];
        commentsHeight += (height + 5);
    }

    return imageHeight + commentsHeight + kButtonWidth;
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

    if (_post)
    {
        if (_post == post)
        {
            return;
        }

        [self _stopObserve:_post];
    }

    _post = post;
    [self _updateImage];
    [self _updateActionBar];
    [self _updateCaption];
    [self _updateComments];
    [self _startObserve:_post];
}

- (void)_startObserve:(JYPost *)post
{
    __weak typeof(self) weakSelf = self;
    [self.observer observe:post keyPath:@"isLiked" options:NSKeyValueObservingOptionNew block:^(JYPostViewCell *cell, JYPost *post, NSDictionary *change) {

        BOOL isLiked = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        [weakSelf _updateLikeButtonImage:isLiked];
    }];

    [self.observer observe:post keyPath:@"likeCount" options:NSKeyValueObservingOptionNew block:^(JYPostViewCell *cell, JYPost *post, NSDictionary *change) {

        NSUInteger likeCount = [change unsignedIntegerValueForKey:NSKeyValueChangeNewKey];
        [weakSelf _updateLikeCount:likeCount];
    }];

    [self.observer observe:post keyPath:@"commentCount" options:NSKeyValueObservingOptionNew block:^(JYPostViewCell *cell, JYPost *post, NSDictionary *change) {

        NSUInteger commentCount = [change unsignedIntegerValueForKey:NSKeyValueChangeNewKey];
        [weakSelf _updateCommentCount:commentCount];
    }];
}

- (void)_stopObserve:(JYPost *)post
{
    [self.observer unobserve:post];
}

- (void)_updateImage
{
    // Use local image
    if (_post.localImage)
    {
        self.photoView.image = _post.localImage;
        return;
    }

    // Fetch network image
    NSURL *url = [NSURL URLWithString:_post.url];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    __weak typeof(self) weakSelf = self;
    [self.photoView setImageWithURLRequest:request
                          placeholderImage:nil
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
                                   {
                                       weakSelf.photoView.image = image;
                                       [weakSelf setNeedsLayout];

                                   } failure:nil];
}


- (void)_updateActionBar
{
    _likeButtonPressed = NO;

    [self _updateLikeButtonImage:_post.isLiked];
    [self _updateLikeCount:_post.likeCount];
    [self _updateCommentCount:_post.commentCount];
}


- (void)_updateLikeButtonImage:(BOOL)isLiked
{
    if (isLiked)
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


- (void)_updateLikeCount:(NSUInteger)count
{
    NSString *likes = NSLocalizedString(@"likes", nil);
    self.likeCountLabel.text = [NSString stringWithFormat:@"%tu %@   ·", count, likes];
}


- (void)_updateCommentCount:(NSUInteger)count
{
    NSString *comments = NSLocalizedString(@"comments", nil);
    self.commentCountButton.textLabel.text = [NSString stringWithFormat:@"%tu %@", count, comments];
}


- (void)_updateCaption
{
    self.captionLabel.text = self.post.caption;
    CGFloat height = [JYPostViewCell labelHeightForText:self.post.caption withFontSize:kFontSizeCaption textAlignment:NSTextAlignmentCenter andWidth:SCREEN_WIDTH];
    self.captionLabel.height = fmax(kCaptionLabelHeightMin, height);

    self.captionLabel.y = SCREEN_WIDTH - self.captionLabel.height;
}


- (void)_updateComments
{
    CGFloat y = CGRectGetMaxY(self.actionBar.frame);

    for (NSUInteger i = 0; i < kBriefCommentsCount; ++i)
    {
        UILabel *label = self.commentLabels[i];
        if (i < _post.commentList.count)
        {
            NSString *text = [NSString stringWithFormat:@"★: %@", _post.commentList[i]];
            label.text = text;

            CGFloat height = [JYPostViewCell labelHeightForText:text withFontSize:kFontSizeComment textAlignment:NSTextAlignmentLeft andWidth:label.width];
            label.height = height + 5;
            label.y = y;
            y = CGRectGetMaxY(label.frame);
        }
        else
        {
            label.y = 0;
            label.height = 0;
            label.text = nil;
        }
    }
}


- (FBKVOController *)observer
{
    if (!_observer)
    {
        _observer = [FBKVOController controllerWithObserver:self];
    }
    return _observer;
}


- (UIImageView *)photoView
{
    if (!_photoView)
    {
        _photoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH)];
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
        _actionBar = [[UIView alloc] initWithFrame:CGRectMake(0, y, SCREEN_WIDTH, kButtonWidth)];
        _actionBar.opaque = YES;
        _actionBar.backgroundColor = JoyyBlack;

        [_actionBar addSubview:self.likeCountLabel];

        [_actionBar addSubview:self.commentCountButton];
        self.commentCountButton.x = CGRectGetMaxX(self.likeCountLabel.frame);

        [_actionBar addSubview:self.likeButton];
        self.likeButton.x =  SCREEN_WIDTH - 2 * kButtonWidth - 2 * kButtonDistance;

        [_actionBar addSubview:self.commentButton];
        self.commentButton.x = CGRectGetMaxX(self.likeButton.frame) + kButtonDistance;
        self.commentButton.y += 1; // The icon is a little bit higher than the like button, add some offset to adjust

        [self addSubview:_actionBar];
    }
    return _actionBar;
}


- (UILabel *)likeCountLabel
{
    if (!_likeCountLabel)
    {
        _likeCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kLikeCountLabelWidth, kButtonWidth)];
        _likeCountLabel.backgroundColor = JoyyBlack;
        _likeCountLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
        _likeCountLabel.textColor = JoyyGray;
        _likeCountLabel.textAlignment = NSTextAlignmentRight;
    }
    return _likeCountLabel;
}


- (JYButton *)commentCountButton
{
    if (!_commentCountButton)
    {
        CGRect frame = CGRectMake(0, 0, kCommentCountButtonWidth, kButtonWidth);
        _commentCountButton = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleTitle shouldMaskImage:NO];
        _commentCountButton.contentColor = JoyyGray;
        _commentCountButton.contentAnimateToColor = JoyyBlue;
        _commentCountButton.foregroundColor = JoyyBlack;
        _commentCountButton.textLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
        [_commentCountButton addTarget:self action:@selector(_showMoreComments) forControlEvents:UIControlEventTouchUpInside];
    }
    return _commentCountButton;
}


- (void)_showMoreComments
{
    NSDictionary *info = @{@"post": self.post, @"edit":@(NO)};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWillCommentPost object:nil userInfo:info];
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


- (UILabel *)captionLabel
{
    if (!_captionLabel)
    {
        CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, 0);
        _captionLabel = [[UILabel alloc] initWithFrame:frame];
        _captionLabel.backgroundColor = JoyyBlack50;
        _captionLabel.font = [UIFont systemFontOfSize:kFontSizeCaption];
        _captionLabel.textColor = JoyyWhite;
        _captionLabel.textAlignment = NSTextAlignmentCenter;
        _captionLabel.numberOfLines = 0;
        _captionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self addSubview:_captionLabel];
    }
    return _captionLabel;
}


- (NSArray *)commentLabels
{
    if (!_commentLabels)
    {
        _commentLabels = [NSMutableArray new];
        for (NSUInteger i = 0; i < kBriefCommentsCount; i++)
        {
            UILabel *label = [self _createLabel];
            [_commentLabels addObject:label];
            [self addSubview:label];
        }
    }
    return _commentLabels;
}


- (UILabel *)_createLabel
{
    CGFloat width = SCREEN_WIDTH - kMarginLeft - kMarginRight;
    CGRect frame = CGRectMake(kMarginLeft, 0, width, 0);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = JoyyBlack;
    label.font = [UIFont systemFontOfSize:kFontSizeComment];
    label.textColor = JoyyWhite;
    label.textAlignment = NSTextAlignmentLeft;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;

    return label;
}


- (JYButton *)_createButtonWithImage:(UIImage *)image
{
    CGRect frame = CGRectMake(0, 0, kButtonWidth, kButtonWidth);
    JYButton *button = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
    button.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    button.imageView.image = image;
    button.contentColor = JoyyGray;
    button.contentAnimateToColor = JoyyBlue;
    button.foregroundColor = ClearColor;

    return button;
}

@end
