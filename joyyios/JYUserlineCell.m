//
//  JYUserPostCell.m
//  joyyios
//
//  Created by Ping Yang on 12/8/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYComment.h"
#import "JYPost.h"
#import "JYPostTimeView.h"
#import "JYPostMediaView.h"
#import "JYUserlineCell.h"

@interface JYUserlineCell ()
@property (nonatomic) JYPostMediaView *mediaView;
@property (nonatomic) JYPostTimeView *timeView;
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
        [self.contentView addSubview:self.timeView];

        NSDictionary *views = @{
                                @"mediaView": self.mediaView,
                                @"timeView": self.timeView
                                };
        NSDictionary *metrics = @{
                                  @"SW":@(SCREEN_WIDTH)
                                  };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[timeView]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[mediaView]-0-|" options:0 metrics:nil views:views]];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0@500-[timeView][mediaView(SW)]-10@500-|" options:0 metrics:metrics views:views]];

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
    self.timeView.post = post;
    self.mediaView.post = post;
}

- (JYPostMediaView *)mediaView
{
    if (!_mediaView)
    {
        _mediaView = [[JYPostMediaView alloc] init];
    }
    return _mediaView;
}

- (JYPostTimeView *)timeView
{
    if (!_timeView)
    {
        _timeView = [[JYPostTimeView alloc] init];
    }
    return _timeView;
}

@end
