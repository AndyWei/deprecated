//
//  JYCommentViewCell.m
//  joyyios
//
//  Created by Ping Yang on 5/14/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYCommentViewCell.h"

static const CGFloat kMinHeight = 20;
static const CGFloat kTopMargin = 8;
static const CGFloat kFontSizeComment = 18.0f;

@implementation JYCommentViewCell

+ (CGFloat)cellHeightForText:(NSString *)text
{
    CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]);
    CGSize maximumSize = CGSizeMake(screenWidth, 10000);

    static UILabel *dummyLabel = nil;
    if (!dummyLabel)
    {
        dummyLabel = [UILabel new];
        dummyLabel.font = [UIFont systemFontOfSize:kFontSizeComment];
        dummyLabel.numberOfLines = 0;
        dummyLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    dummyLabel.text = text;
    CGSize expectSize = [dummyLabel sizeThatFits:maximumSize];
    CGFloat height = fmax(expectSize.height, kMinHeight);

    return height;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = FlatWhite;

        [self _createCommentLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.commentLabel.height = self.height - kTopMargin;
}


- (void)_createCommentLabel
{
    CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]);
    CGRect frame = CGRectMake(0, kTopMargin, screenWidth, kMinHeight);
    self.commentLabel = [[UILabel alloc] initWithFrame:frame];
    self.commentLabel.font = [UIFont systemFontOfSize:15.0f];
    self.commentLabel.textColor = FlatGrayDark;
    self.commentLabel.textAlignment = NSTextAlignmentCenter;
    self.commentLabel.backgroundColor = FlatWhite;

    [self addSubview:self.commentLabel];
}

@end
