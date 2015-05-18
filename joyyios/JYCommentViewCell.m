//
//  JYCommentViewCell.m
//  joyyios
//
//  Created by Ping Yang on 5/14/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYCommentViewCell.h"

static const CGFloat kMinHeight = 20;
static const CGFloat kLeftMargin = 8;
static const CGFloat kRightMargin = 8;
static const CGFloat kTopMargin = 8;
static const CGFloat kFontSizeComment = 18.0f;

@interface JYCommentViewCell ()

@property(nonatomic) UILabel *commentLabel;

@end


@implementation JYCommentViewCell

+ (CGFloat)cellHeightForComment:(NSDictionary *)comment
{
    CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]);
    CGSize maximumSize = CGSizeMake(screenWidth - kLeftMargin - kRightMargin, 10000);

    NSString *text = [[self class ] _textOf:comment];
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

+ (NSString *)_textOf:(NSDictionary *)comment
{
    NSString *fromUser = [comment objectForKey:@"username"];
    NSString *toUser = [comment objectForKey:@"to_username"];
    NSString *contents = [comment objectForKey:@"contents"];

    if (toUser)
    {
        return [NSString stringWithFormat:@"%@ @%@ %@", fromUser, toUser, contents];
    }
    else
    {
        return [NSString stringWithFormat:@"%@ %@", fromUser, contents];
    }
}

- (void)presentComment:(NSDictionary *)comment
{
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = JoyyWhite;

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
    CGRect frame = CGRectMake(kLeftMargin, kTopMargin, screenWidth- kLeftMargin - kRightMargin, kMinHeight);
    self.commentLabel = [[UILabel alloc] initWithFrame:frame];
    self.commentLabel.backgroundColor = JoyyWhite;
    self.commentLabel.font = [UIFont systemFontOfSize:15.0f];
    self.commentLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.commentLabel.numberOfLines = 0;
    self.commentLabel.textColor = FlatGrayDark;
    self.commentLabel.textAlignment = NSTextAlignmentLeft;

    [self addSubview:self.commentLabel];
}

@end
