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
static const CGFloat kFontSizeComment = 16.0f;

@interface JYCommentViewCell ()

@property(nonatomic, weak) TTTAttributedLabel *commentLabel;

@end


@implementation JYCommentViewCell

+ (CGFloat)cellHeightForComment:(JYComment *)comment
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

- (void)presentComment:(JYComment *)comment
{
    NSString *labelText = comment.contentString;
    NSRange range = [labelText rangeOfString:comment.username];

    // Bold the username
    [self.commentLabel setText:labelText afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {

        UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:kFontSizeComment];
        CTFontRef boldFont = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
        if (boldFont)
        {
            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)boldFont range:range];
            CFRelease(boldFont);
        }
        return mutableAttributedString;
    }];

    // Add link to username
    NSString *url = [NSString stringWithFormat:@"user://%@", comment.username];
    [self.commentLabel addLinkToURL:[NSURL URLWithString:url] withRange:range];

    // Add link to the handles in body text. E.g., @mike @jack
    [self _highlightMentions];
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

- (void)_createCommentLabel
{
    CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]);
    CGRect frame = CGRectMake(kMarginLeft, kTopMargin, screenWidth- kMarginLeft - kMarginRight, kMinHeight);

    TTTAttributedLabel *commentLabel = [[TTTAttributedLabel alloc] initWithFrame:frame];;
    commentLabel.delegate = self;
    commentLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    commentLabel.backgroundColor = FlatWhite;
    commentLabel.font = [UIFont systemFontOfSize:kFontSizeComment];
    commentLabel.lineBreakMode = NSLineBreakByWordWrapping;
    commentLabel.numberOfLines = 0;
    commentLabel.textColor = FlatBlack;
    commentLabel.textAlignment = NSTextAlignmentLeft;
    commentLabel.linkAttributes =  @{ (id)kCTForegroundColorAttributeName: FlatSkyBlueDark,
                                           (id)kCTUnderlineStyleAttributeName : [NSNumber numberWithInt:NSUnderlineStyleNone] };

    self.commentLabel = commentLabel;
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
