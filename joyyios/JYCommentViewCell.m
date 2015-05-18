//
//  JYCommentViewCell.m
//  joyyios
//
//  Created by Ping Yang on 5/14/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYCommentViewCell.h"

static const CGFloat kMinHeight = 10;
static const CGFloat kLeftMargin = 8;
static const CGFloat kRightMargin = 8;
static const CGFloat kTopMargin = 3;
static const CGFloat kFontSizeComment = 17.0f;

@interface JYCommentViewCell ()

@property(nonatomic) TTTAttributedLabel *commentLabel;

@end


@implementation JYCommentViewCell

+ (CGFloat)cellHeightForComment:(NSDictionary *)comment
{
    CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]);
    CGSize maximumSize = CGSizeMake(screenWidth - kLeftMargin - kRightMargin, 10000);

    static UILabel *dummyLabel = nil;
    if (!dummyLabel)
    {
        dummyLabel = [UILabel new];
        dummyLabel.font = [UIFont systemFontOfSize:kFontSizeComment];
        dummyLabel.numberOfLines = 0;
        dummyLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    dummyLabel.text = [[self class ] _textOf:comment];
    CGSize expectSize = [dummyLabel sizeThatFits:maximumSize];
    CGFloat height = expectSize.height + kTopMargin;

    return height;
}

+ (NSString *)_textOf:(NSDictionary *)comment
{
    NSString *fromUsername = [comment objectForKey:@"username"];
    NSString *toUsername = [comment objectForKey:@"to_username"];
    NSString *contents = [comment objectForKey:@"contents"];
    NSString *reply = NSLocalizedString(@"reply", nil);

    if ([toUsername isKindOfClass:[NSNull class]])
    {
        return [NSString stringWithFormat:@"%@: %@", fromUsername, contents];
    }
    else
    {
        return [NSString stringWithFormat:@"%@ %@ @%@: %@", fromUsername, reply, toUsername, contents];
    }
}

- (void)presentComment:(NSDictionary *)comment
{
    NSString *labelText = [[self class ] _textOf:comment];
    self.commentLabel.text = labelText;

    NSString *fromUsername = [comment objectForKey:@"username"];
    NSRange range = [labelText rangeOfString:fromUsername];
    NSString *url = [NSString stringWithFormat:@"user://%@", fromUsername];
    [self.commentLabel addLinkToURL:[NSURL URLWithString:url] withRange:range];

    NSString *toUsername = [comment objectForKey:@"to_username"];
    if (![toUsername isKindOfClass:[NSNull class]])
    {
        range = [labelText rangeOfString:[NSString stringWithFormat:@"@%@", toUsername]];
        url = [NSString stringWithFormat:@"user://%@", toUsername];
        [self.commentLabel addLinkToURL:[NSURL URLWithString:url] withRange:range];
    }
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
    self.commentLabel = [[TTTAttributedLabel alloc] initWithFrame:frame];
    self.commentLabel.delegate = self;

    self.commentLabel.backgroundColor = JoyyWhite;
    self.commentLabel.font = [UIFont systemFontOfSize:kFontSizeComment];
    self.commentLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.commentLabel.numberOfLines = 0;
    self.commentLabel.textColor = FlatBlack;
    self.commentLabel.textAlignment = NSTextAlignmentLeft;

    self.commentLabel.linkAttributes =  @{ (id)kCTForegroundColorAttributeName: FlatSkyBlueDark,
                                           (id)kCTUnderlineStyleAttributeName : [NSNumber numberWithInt:NSUnderlineStyleNone] };

    [self addSubview:self.commentLabel];
}

# pragma -mark TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if ([[url scheme] hasPrefix:@"user"])
    {
        NSLog(@"tap on username = %@", [url host]);
        // TODO: make the viewController a delegate and call it delegate method to present user profile view
    }
}

@end
