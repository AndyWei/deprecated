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
#import "JYPost.h"
#import "JYPostViewCell.h"

static const CGFloat kActionBarHeight = 40;
static const CGFloat kButtonWidth = kActionBarHeight;
static const CGFloat kButtonDistance = 20;
static const CGFloat kCommentCountButtonWidth = 100;
static const CGFloat kLikeCountLabelWidth = 80;

@interface JYPostViewCell () <TTTAttributedLabelDelegate>
@property(nonatomic) BOOL likeButtonPressed;
@property(nonatomic) FBKVOController *observer;
@property(nonatomic) JYButton *commentButton;
@property(nonatomic) JYButton *commentCountButton;
@property(nonatomic) JYButton *likeButton;
@property(nonatomic) NSMutableArray *commentLabels;
@property(nonatomic) TTTAttributedLabel *captionLabel;
@property(nonatomic) UIImageView *photoView;
@property(nonatomic) UILabel *likeCountLabel;
@property(nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property(nonatomic) UIView *actionBar;
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
        NSString *text = [JYPostViewCell dummyTextOfString:comment.content];
        CGFloat height = [JYPostViewCell labelHeightForText:text withFontSize:kFontSizeComment textAlignment:NSTextAlignmentLeft andWidth:[JYPostViewCell textAreaWidth]];
        commentsHeight += (height + 5);
    }

    return imageHeight + commentsHeight + kActionBarHeight;
}

+ (CGFloat)textAreaWidth
{
    return (SCREEN_WIDTH - kMarginLeft - kMarginRight);
}

+ (NSString *)dummyTextOfString:(NSString *)original
{
    return [NSString stringWithFormat:@"🐨: %@", original];
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

- (NSString *)_displayTextOfComment:(JYComment *)comment
{
    NSUInteger code = self.post.postId + comment.ownerId;
    JYAvatar *avatar = [JYAvatar avatarOfCode:code];
    return [NSString stringWithFormat:@"%@: %@", avatar.symbol, comment.content];
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

        [weakSelf _updateLikeCount];
    }];

    [self.observer observe:post keyPath:@"commentCount" options:NSKeyValueObservingOptionNew block:^(JYPostViewCell *cell, JYPost *post, NSDictionary *change) {

        [weakSelf _updateCommentCount];
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

- (void)_updateActionBar
{
    _likeButtonPressed = NO;

    [self _updateLikeButtonImage];
    [self _updateLikeCount];
    [self _updateCommentCount];
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

- (void)_updateLikeCount
{
    NSString *likes = NSLocalizedString(@"likes", nil);
    self.likeCountLabel.text = [NSString stringWithFormat:@"%tu %@   ·", self.post.likeCount, likes];
}

- (void)_updateCommentCount
{
    NSString *comments = NSLocalizedString(@"comments", nil);
    self.commentCountButton.textLabel.text = [NSString stringWithFormat:@"%tu %@", self.post.commentCount, comments];
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
    CGFloat y = CGRectGetMaxY(self.actionBar.frame);

    for (NSUInteger i = 0; i < kRecentCommentsLimit; ++i)
    {
        TTTAttributedLabel *label = self.commentLabels[i];
        if (i < _post.commentList.count)
        {
            JYComment *comment = _post.commentList[i];
            NSString *text = [self _displayTextOfComment:comment];
            label.text = text;
            NSRange range = NSMakeRange(0, text.length);
            [label addLinkToURL:[NSURL URLWithString:@"comment://list"] withRange:range];

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
        _actionBar = [[UIView alloc] initWithFrame:CGRectMake(0, y, SCREEN_WIDTH, kActionBarHeight)];
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
        _likeCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kLikeCountLabelWidth, kActionBarHeight)];
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
        CGRect frame = CGRectMake(0, 0, kCommentCountButtonWidth, kActionBarHeight);
        _commentCountButton = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleTitle shouldMaskImage:NO];
        _commentCountButton.contentColor = JoyyGray;
        _commentCountButton.contentAnimateToColor = JoyyBlue;
        _commentCountButton.foregroundColor = JoyyBlack;
        _commentCountButton.textLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
        [_commentCountButton addTarget:self action:@selector(_showAllComments) forControlEvents:UIControlEventTouchUpInside];
    }
    return _commentCountButton;
}

- (void)_showAllComments
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

- (TTTAttributedLabel *)captionLabel
{
    if (!_captionLabel)
    {
        CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, 0);
        _captionLabel = [[TTTAttributedLabel alloc] initWithFrame:frame];
        _captionLabel.backgroundColor = JoyyBlack80;
        _captionLabel.font = [UIFont systemFontOfSize:kFontSizeCaption];
        _captionLabel.textColor = JoyyWhite;
        _captionLabel.textAlignment = NSTextAlignmentCenter;
        _captionLabel.numberOfLines = 0;
        _captionLabel.lineBreakMode = NSLineBreakByWordWrapping;

        _captionLabel.layer.cornerRadius = 4;
        _captionLabel.clipsToBounds = YES;
        [self addSubview:_captionLabel];
    }
    return _captionLabel;
}

- (NSMutableArray *)commentLabels
{
    if (!_commentLabels)
    {
        _commentLabels = [NSMutableArray new];
        for (NSUInteger i = 0; i < kRecentCommentsLimit; i++)
        {
            TTTAttributedLabel *label = [self _createCommentLabel];

            [_commentLabels addObject:label];
            [self addSubview:label];
        }
    }
    return _commentLabels;
}

- (TTTAttributedLabel *)_createCommentLabel
{
    CGRect frame = CGRectMake(kMarginLeft, 0, [[self class] textAreaWidth], 0);
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
    label.delegate = self;
    label.backgroundColor = JoyyBlack;
    label.font = [UIFont systemFontOfSize:kFontSizeComment];
    label.textColor = JoyyWhite;
    label.textAlignment = NSTextAlignmentLeft;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.activeLinkAttributes = nil; // Do not change color on link is being tapped
    label.linkAttributes =  @{ (id)kCTForegroundColorAttributeName: JoyyWhite,
                               (id)kCTUnderlineStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleNone]
                             };

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

# pragma -mark TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if ([[url scheme] hasPrefix:@"comment"])
    {
        [self _showAllComments];
    }
}

@end
