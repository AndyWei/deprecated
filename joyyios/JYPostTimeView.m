//
//  JYPostTimeView.m
//  joyyios
//
//  Created by Ping Yang on 12/9/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYButton.h"
#import "JYPost.h"
#import "JYPostTimeView.h"
#import "NSDate+Joyy.h"

@interface JYPostTimeView ()
@property (nonatomic) TTTAttributedLabel *postTimeLabel;
@end


@implementation JYPostTimeView

- (instancetype)init
{
    if (self = [super init])
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.postTimeLabel];

        NSDictionary *views = @{
                                @"postTimeLabel": self.postTimeLabel
                                };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[postTimeLabel]-0-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[postTimeLabel]-0-|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)setPost:(JYPost *)post
{
    _post = post;

    if (!_post)
    {
        self.postTimeLabel.text = nil;
        return;
    }

    NSDate *date = [NSDate dateOfId:self.post.postId];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];

    self.postTimeLabel.text = [date localeStringWithDateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
}

- (TTTAttributedLabel *)postTimeLabel
{
    if (!_postTimeLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:kFontSizeDetail];
        label.textColor = JoyyGray;
        label.backgroundColor = JoyyWhitePure;
        label.textAlignment = NSTextAlignmentRight;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;

        _postTimeLabel = label;
    }
    return _postTimeLabel;
}

@end
