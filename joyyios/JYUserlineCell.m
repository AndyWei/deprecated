//
//  JYUserPostCell.m
//  joyyios
//
//  Created by Ping Yang on 12/8/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYPost.h"
#import "JYPostMediaView.h"
#import "JYUserlineCell.h"
#import "NSDate+Joyy.h"

@interface JYUserlineCell ()
@property (nonatomic) JYPostMediaView *mediaView;
@property (nonatomic) TTTAttributedLabel *postTimeLabel;
@end

@implementation JYUserlineCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = JoyyWhitePure;

        [self.contentView addSubview:self.mediaView];
        [self.contentView addSubview:self.postTimeLabel];

        NSDictionary *views = @{
                                @"mediaView": self.mediaView,
                                @"postTimeLabel": self.postTimeLabel
                                };
        NSDictionary *metrics = @{
                                  @"SW":@(SCREEN_WIDTH)
                                  };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[postTimeLabel]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[mediaView]-0-|" options:0 metrics:nil views:views]];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0@500-[postTimeLabel][mediaView(SW)]-10@500-|" options:0 metrics:metrics views:views]];

    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.post = nil;
}

- (void)setPost:(JYPost *)post
{
    _post = post;
    self.mediaView.post = post;

    if (!post)
    {
        self.postTimeLabel.text = nil;
        return;
    }
    
    NSDate *date = [NSDate dateOfId:_post.postId];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];

    self.postTimeLabel.text = [date localeStringWithDateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
}

- (JYPostMediaView *)mediaView
{
    if (!_mediaView)
    {
        _mediaView = [[JYPostMediaView alloc] init];
    }
    return _mediaView;
}

- (TTTAttributedLabel *)postTimeLabel
{
    if (!_postTimeLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:kFontSizeDetail];
        label.textColor = JoyyGray;
        label.backgroundColor = ClearColor;
        label.textAlignment = NSTextAlignmentRight;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;

        _postTimeLabel = label;
    }
    return _postTimeLabel;
}

@end
