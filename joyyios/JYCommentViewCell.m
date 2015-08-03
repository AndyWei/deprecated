//
//  JYCommentViewCell.m
//  joyyios
//
//  Created by Ping Yang on 5/14/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYCommentViewCell.h"

static const CGFloat kMinHeight = 10;
static const CGFloat kTopMargin = 3;


@interface JYCommentViewCell ()

@property(nonatomic) TTTAttributedLabel *commentLabel;

@end


@implementation JYCommentViewCell

+ (CGFloat)heightForComment:(JYComment *)comment
{
    CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]);
    CGSize maximumSize = CGSizeMake(screenWidth - kMarginLeft - kMarginRight, 10000);

    static UILabel *dummyLabel = nil;
    if (!dummyLabel)
    {
        dummyLabel = [UILabel new];
        dummyLabel.font = [UIFont systemFontOfSize:kFontSizeComment];
        dummyLabel.numberOfLines = 0;
        dummyLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    dummyLabel.text = comment.contentString;
    CGSize expectSize = [dummyLabel sizeThatFits:maximumSize];
    CGFloat height = expectSize.height + kTopMargin;

    return height;
}

- (void)setComment:(JYComment *)comment
{
    _comment = comment;
    self.commentLabel.text = comment.contentString;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = JoyyWhite;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.commentLabel.height = self.height - kTopMargin;
}

- (void)_highlightMentions
{
    NSRegularExpression *mentionExpression = [NSRegularExpression regularExpressionWithPattern:@"(?:^|\\s)(@\\w+)" options:NO error:nil];

    NSString *text = self.commentLabel.text;
    NSArray *matches = [mentionExpression matchesInString:text options:0 range:NSMakeRange(0, [text length])];

    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = [match rangeAtIndex:1];
        NSString *mentionString = [text substringWithRange:matchRange];
        NSRange linkRange = [text rangeOfString:mentionString];
        NSString* username = [mentionString substringFromIndex:1];
        NSString* linkURLString = [NSString stringWithFormat:@"user://%@", username];
        [self.commentLabel addLinkToURL:[NSURL URLWithString:linkURLString] withRange:linkRange];
    }
}

- (TTTAttributedLabel *)commentLabel
{
    if (!_commentLabel)
    {
        CGRect frame = CGRectMake(kMarginLeft, kTopMargin, SCREEN_WIDTH - kMarginLeft - kMarginRight, kMinHeight);

        _commentLabel = [[TTTAttributedLabel alloc] initWithFrame:frame];;
        _commentLabel.delegate = self;
        _commentLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
        _commentLabel.backgroundColor = FlatWhite;
        _commentLabel.font = [UIFont systemFontOfSize:kFontSizeComment];
        _commentLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _commentLabel.numberOfLines = 0;
        _commentLabel.textColor = FlatBlack;
        _commentLabel.textAlignment = NSTextAlignmentLeft;
        _commentLabel.linkAttributes =  @{ (id)kCTForegroundColorAttributeName: FlatSkyBlueDark,
                                               (id)kCTUnderlineStyleAttributeName : [NSNumber numberWithInt:NSUnderlineStyleNone] };
        [self addSubview:_commentLabel];
    }
    return _commentLabel;
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
