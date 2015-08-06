//
//  JYCommentViewCell.m
//  joyyios
//
//  Created by Ping Yang on 5/14/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYCommentViewCell.h"

static const CGFloat kAvatarWidth = 40;
static const CGFloat kCommentLabelHeightMin = 80;

@interface JYCommentViewCell ()

@property(nonatomic) UIImageView *avatar;
@property(nonatomic) TTTAttributedLabel *commentLabel;

@end


@implementation JYCommentViewCell

+ (CGFloat)heightForComment:(JYComment *)comment
{
    CGSize maximumSize = CGSizeMake([JYCommentViewCell labelWidth], MAXFLOAT);

    static TTTAttributedLabel *dummyLabel = nil;
    if (!dummyLabel)
    {
        dummyLabel = [JYCommentViewCell _createCommentLabel];
    }
    dummyLabel.text = comment.contentString;
    CGSize expectSize = [dummyLabel sizeThatFits:maximumSize];
    CGFloat height = fmax(kCommentLabelHeightMin, expectSize.height) + 1;

    return height;
}

+ (TTTAttributedLabel *)_createCommentLabel
{
    CGRect frame = CGRectMake(0, 0, [JYCommentViewCell labelWidth], kCommentLabelHeightMin);
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
    label.textInsets = UIEdgeInsetsMake(3, 0, 3, kMarginRight);
    label.backgroundColor = JoyyGrayDark;
    label.font = [UIFont systemFontOfSize:kFontSizeComment];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.textColor = JoyyWhite;
    label.textAlignment = NSTextAlignmentLeft;
    return label;
}

+ (CGFloat)labelWidth
{
    CGFloat margin = (kCommentLabelHeightMin - kAvatarWidth) / 2;
    CGFloat labelWidth = SCREEN_WIDTH - kAvatarWidth - 2 * margin;
    return labelWidth;
}

- (void)setComment:(JYComment *)comment
{
    _comment = comment;
    self.commentLabel.text = comment.contentString;
    self.commentLabel.height = [JYCommentViewCell heightForComment:self.comment] - 1;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = JoyyGrayDark;
    }
    return self;
}

- (UIImageView *)avatar
{
    if (!_avatar)
    {
        // Circle shape UIImageView
        CGFloat margin = (kCommentLabelHeightMin - kAvatarWidth) / 2;
        _avatar = [[UIImageView alloc] initWithFrame:CGRectMake(margin, margin, kAvatarWidth, kAvatarWidth)];
        _avatar.layer.cornerRadius = kAvatarWidth / 2;
        _avatar.clipsToBounds = YES;
        _avatar.contentMode = UIViewContentModeCenter;

        // Border and Border color
        _avatar.layer.borderWidth = 1.0f;
        _avatar.layer.borderColor = JoyyWhite.CGColor;

        // TODO: hashed image and backgorund color
        _avatar.image = [UIImage imageNamed:@"mask"];
        _avatar.backgroundColor = FlatWatermelonDark;


        [self addSubview:_avatar];
    }
    return _avatar;
}

- (TTTAttributedLabel *)commentLabel
{
    if (!_commentLabel)
    {
        _commentLabel = [JYCommentViewCell _createCommentLabel];
        CGFloat margin = (kCommentLabelHeightMin - kAvatarWidth) / 2;
        _commentLabel.x = CGRectGetMaxX(self.avatar.frame) + margin;
        [self addSubview:_commentLabel];
    }
    return _commentLabel;
}

@end
