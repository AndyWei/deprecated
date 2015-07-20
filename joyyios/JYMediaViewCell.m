//
//  JYMediaViewCell.m
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>

#import "JYButton.h"
#import "JYMedia.h"
#import "JYMediaViewCell.h"

static const CGFloat kActionBarHeight = 40;
static const CGFloat kButtonWidth = 23;
static const CGFloat kCaptionMinHeight = 40;
static const CGFloat kCommentCountLabelHeight = 40;

@interface JYMediaViewCell ()

@property(nonatomic) UIImageView *photoView;
@property(nonatomic) UILabel *captionLabel;

@property(nonatomic) UIView *actionBar;
@property(nonatomic) UILabel *briefLabel;
@property(nonatomic) JYButton *likeButton;
@property(nonatomic) JYButton *commentButton;

@end


@implementation JYMediaViewCell

+ (CGFloat)labelHeightForText:(NSString *)text withFontSize:(CGFloat)fontSize
{
    CGFloat labelWidth = SCREEN_WIDTH - kMarginLeft - kMarginRight;
    CGSize maximumSize = CGSizeMake(labelWidth, 10000);

    static UILabel *dummyLabel = nil;
    if (!dummyLabel)
    {
        dummyLabel = [UILabel new];
        dummyLabel.font = [UIFont systemFontOfSize:fontSize];
        dummyLabel.textAlignment = NSTextAlignmentCenter;
        dummyLabel.numberOfLines = 0;
        dummyLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    dummyLabel.text = text;
    CGSize expectSize = [dummyLabel sizeThatFits:maximumSize];
    CGFloat labelHeight = fmax(expectSize.height, kCaptionMinHeight);

    return labelHeight;
}

+ (CGFloat)heightForMedia:(JYMedia *)media;
{
    CGFloat imageHeight = SCREEN_WIDTH;
    CGFloat captionHeight = [JYMediaViewCell labelHeightForText:media.caption withFontSize:kFontSizeBody];
    return imageHeight + captionHeight + kActionBarHeight + kCommentCountLabelHeight;
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

- (void)setMedia:(JYMedia *)media
{
    if (!media)
    {
        return;
    }

    _media = media;
    [self _updateImage];
    [self _updateActionBar];
    [self _updateCaption];
}

- (void)_updateImage
{
    // Use local image
    if (_media.localImage)
    {
        self.photoView.image = _media.localImage;
        return;
    }

    // Fetch network image
    NSURL *url = [NSURL URLWithString:_media.url];
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
    if (_media.isLiked)
    {
        self.likeButton.imageView.image = [UIImage imageNamed:@"heart_selected"];
        self.likeButton.contentColor = JoyyBlue;
    }
    else
    {
        self.likeButton.imageView.image = [UIImage imageNamed:@"heart"];
        self.likeButton.contentColor = JoyyGray;
    }

    NSString *likes = NSLocalizedString(@"likes", nil);
    NSString *comments = NSLocalizedString(@"comments", nil);
    self.briefLabel.text = [NSString stringWithFormat:@"%tu %@ · %tu %@", _media.likeCount, likes,_media.commentCount, comments];
}

- (void)_updateCaption
{
    self.captionLabel.text = _media.caption;
    self.captionLabel.height = [JYMediaViewCell labelHeightForText:_media.caption withFontSize:kFontSizeBody];
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

        [_actionBar addSubview:self.briefLabel];

        [_actionBar addSubview:self.likeButton];
        self.likeButton.x = CGRectGetMaxX(self.briefLabel.frame);

        [_actionBar addSubview:self.commentButton];
        self.commentButton.x = CGRectGetMaxX(self.likeButton.frame) + kButtonWidth;
        self.commentButton.y += 1; // The icon is a little bit higher than the like button, add some offset to adjust

        [self addSubview:_actionBar];
    }
    return _actionBar;
}

- (UILabel *)briefLabel
{
    if (!_briefLabel)
    {
        CGFloat width = SCREEN_WIDTH - kMarginLeft - 4 * kButtonWidth;
        _briefLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMarginLeft, 0, width, kActionBarHeight)];
        _briefLabel.backgroundColor = JoyyBlack;
        _briefLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
        _briefLabel.textColor = JoyyGray;
        _briefLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _briefLabel;
}

- (JYButton *)commentButton
{
    if (!_commentButton)
    {
        _commentButton = [self _createButtonWithImage:[UIImage imageNamed:@"comment"]];
        _commentButton.contentAnimateToColor = JoyyBlue;
        [_commentButton addTarget:self action:@selector(_comment) forControlEvents:UIControlEventTouchDown];
    }
    return _commentButton;
}

- (void)_comment
{
}

- (JYButton *)likeButton
{
    if (!_likeButton)
    {
        _likeButton = [self _createButtonWithImage:[UIImage imageNamed:@"heart"]];
        [_likeButton addTarget:self action:@selector(_like) forControlEvents:UIControlEventTouchDown];
    }
    return _likeButton;
}

- (void)_like
{
    if (!self.media || self.media.isLiked)
    {
        return;
    }

    self.likeButton.imageView.image = [UIImage imageNamed:@"heart_selected"];
    self.likeButton.contentColor = JoyyBlue;
    self.media.isLiked = YES;

    NSDictionary *info = [NSDictionary dictionaryWithObject:self.media forKey:@"media"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidLikeMedia object:nil userInfo:info];
}

- (UILabel *)captionLabel
{
    if (!_captionLabel)
    {
        _captionLabel = [self _createLabel];
        _captionLabel.y = CGRectGetMaxY(self.actionBar.frame);
        [self addSubview:_captionLabel];
    }
    return _captionLabel;
}

- (UILabel *)_createLabel
{
    CGFloat width = SCREEN_WIDTH - kMarginLeft - kMarginRight;
    CGRect frame = CGRectMake(kMarginLeft, 0, width, 0);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = JoyyBlack;
    label.font = [UIFont systemFontOfSize:kFontSizeBody];
    label.textColor = JoyyWhite;
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;

    return label;
}

- (JYButton *)_createButtonWithImage:(UIImage *)image
{
    CGRect frame = CGRectMake(0, 10, kButtonWidth, kButtonWidth);
    JYButton *button = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];

    button.imageView.image = image;
    button.contentColor = JoyyGray;
    button.foregroundColor = ClearColor;

    return button;
}

@end
