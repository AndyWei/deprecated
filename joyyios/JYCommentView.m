//
//  JYCommentView.m
//  joyyios
//
//  Created by Ping Yang on 8/6/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYCommentView.h"

@interface JYCommentView ()
@property(nonatomic) TTTAttributedLabel *commentLabel;
@property(nonatomic) UIImageView *avatar;
@end

static const CGFloat kAvatarWidth = 40;
static const CGFloat kCommentLabelHeightMin = 60;
static const CGFloat kSpaceH = (kCommentLabelHeightMin - kAvatarWidth);
static const CGFloat kSpaceV = kSpaceH / 2;


@implementation JYCommentView

+ (CGFloat)heightForText:(NSString *)text
{
    if (!text)
    {
        return kCommentLabelHeightMin;
    }

    CGSize maximumSize = CGSizeMake([JYCommentView labelWidth], MAXFLOAT);

    static TTTAttributedLabel *dummyLabel = nil;
    if (!dummyLabel)
    {
        dummyLabel = [JYCommentView _createCommentLabel];
    }
    dummyLabel.text = text;
    CGSize expectSize = [dummyLabel sizeThatFits:maximumSize];
    CGFloat height = fmax(kCommentLabelHeightMin, expectSize.height);

    return height;
}

+ (CGFloat)heightForComment:(JYComment *)comment
{
    if (!comment)
    {
        return kCommentLabelHeightMin;
    }

    return[JYCommentView heightForText:comment.content];
}

+ (TTTAttributedLabel *)_createCommentLabel
{
    CGRect frame = CGRectMake(0, 0, [JYCommentView labelWidth], kCommentLabelHeightMin);
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
    label.textInsets = UIEdgeInsetsMake(3, 0, 3, kMarginRight);
    label.backgroundColor = ClearColor;
    label.font = [UIFont systemFontOfSize:kFontSizeComment];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.textColor = JoyyWhite;
    label.textAlignment = NSTextAlignmentLeft;
    return label;
}

+ (CGFloat)labelWidth
{
    CGFloat labelWidth = SCREEN_WIDTH - kAvatarWidth - 2 * kSpaceH;
    return labelWidth;
}

+ (UIColor *)colorForIndex:(uint)index
{
    static NSArray *colorMap = nil;
    if (!colorMap)
    {
        colorMap = @[FlatBlue, FlatCoffee, FlatLime, FlatMagenta, FlatMaroon, FlatMint, FlatOrange, FlatPink];
    }

    return colorMap[index];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = JoyyBlack50;
    }
    return self;
}

- (void)setCaption:(NSString *)caption
{
    if (!caption)
    {
        self.avatar.image = nil;
        self.commentLabel.text = nil;
        return;
    }

    if (_caption == caption)
    {
        return;
    }

    _caption = caption;
    self.commentLabel.text = caption;
    CGFloat height = [[self class] heightForText:caption];
    self.commentLabel.height = self.height = height;

    self.avatar.image = [UIImage imageNamed:@"avt"];
    self.avatar.backgroundColor = JoyyBlue;
}

- (void)setComment:(JYComment *)comment
{
    if (!comment)
    {
        self.avatar.image = nil;
        self.avatar.backgroundColor = ClearColor;
        self.commentLabel.text = nil;
        self.height = self.commentLabel.height = kCommentLabelHeightMin;
        return;
    }

    _comment = comment;
    self.commentLabel.text = comment.content;
    CGFloat height = [[self class] heightForComment:_comment];
    self.commentLabel.height = self.height = height;

    [self _updateAvatar];
}

- (void)_updateAvatar
{
    // calculate image and backgorund color
    NSUInteger seed = self.comment.ownerId + self.comment.postId;

    // md5 hash
    NSString *str = [NSString stringWithFormat:@"%020tu", seed];
    const char *cstr = [str UTF8String];
    unsigned char md5[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cstr, (CC_LONG)strlen(cstr), md5);

    uint avatarIndex = 0;
    for (uint i = 0; i < CC_MD5_DIGEST_LENGTH; ++i)
    {
        avatarIndex += md5[i];
    }

    uint colorIndex = avatarIndex % 8;
    uint imageIndex = (avatarIndex / 8) % 20;

    NSString *imageName = [NSString stringWithFormat:@"avt%02d", imageIndex];
    self.avatar.image = [UIImage imageNamed:imageName];
    self.avatar.backgroundColor = [JYCommentView colorForIndex:colorIndex];
}

- (UIImageView *)avatar
{
    if (!_avatar)
    {
        // Circle shape UIImageView
        _avatar = [[UIImageView alloc] initWithFrame:CGRectMake(kSpaceH, kSpaceV, kAvatarWidth, kAvatarWidth)];
        _avatar.layer.cornerRadius = kAvatarWidth/2;
        _avatar.layer.masksToBounds = YES;
        _avatar.layer.borderWidth = 0;
        _avatar.contentMode = UIViewContentModeCenter;

        [self addSubview:_avatar];
    }
    return _avatar;
}

- (TTTAttributedLabel *)commentLabel
{
    if (!_commentLabel)
    {
        _commentLabel = [JYCommentView _createCommentLabel];
        _commentLabel.x = kAvatarWidth + 2 * kSpaceH;
        [self addSubview:_commentLabel];
    }
    return _commentLabel;
}

@end
