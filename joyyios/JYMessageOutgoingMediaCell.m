//
//  JYMessageOutgoingMediaCell.m
//  joyyios
//
//  Created by Ping Yang on 2/16/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <M13ProgressSuite/M13ProgressViewPie.h>

#import "JYMessageOutgoingMediaCell.h"

@interface JYMessageOutgoingMediaCell ()
@property (nonatomic) M13ProgressViewPie *progressView;
@end

@implementation JYMessageOutgoingMediaCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        NSDictionary *views = @{
                                @"topLabel": self.topLabel,
                                @"avatarView": self.avatarView,
                                @"mediaContainerView": self.mediaContainerView
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=50@500)-[mediaContainerView]-10-[avatarView(35)]-10-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[topLabel]-10-[avatarView(35)]-(>=10@500)-|" options:0 metrics:nil views:views]];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[topLabel]-10-[mediaContainerView]-(>=10@500)-|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)setMessage:(JYMessage *)message
{
    [super setMessage:message];
    [self _updateProgressView];
}

- (void)_updateProgressView
{
    self.progressView.centerX = self.contentImageView.centerX;
    self.progressView.centerY = self.contentImageView.centerY;

    if (self.message.uploadStatus == JYMessageUploadStatusNone)
    {
        self.progressView.alpha = 0.0f;
    }
    else if (self.message.uploadStatus == JYMessageUploadStatusOngoing)
    {
        self.progressView.primaryColor = JoyyBlue;
        self.progressView.secondaryColor = JoyyBlue;
        self.progressView.alpha = 1.0f;
        self.progressView.animationDuration = 0.5f;
        [self.progressView setProgress:0.0f animated:NO];
        [self.progressView setProgress:1.0f animated:YES];
    }
    else if (self.message.uploadStatus == JYMessageUploadStatusSuccess)
    {
        [self.progressView performAction:M13ProgressViewActionSuccess animated:YES];
        self.message.uploadStatus = JYMessageUploadStatusNone;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.progressView.alpha = 0.0f;
        });
    }
    else if (self.message.uploadStatus == JYMessageUploadStatusFailure)
    {
        self.progressView.primaryColor = JoyyRedPure;
        self.progressView.secondaryColor = JoyyRedPure;
        [self.progressView performAction:M13ProgressViewActionFailure animated:YES];
    }
}

- (M13ProgressViewPie *)progressView
{
    if (!_progressView)
    {
        _progressView = [[M13ProgressViewPie alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _progressView.primaryColor = JoyyBlue;
        _progressView.secondaryColor = JoyyBlue;

        [self.contentImageView addSubview:_progressView];
    }
    return _progressView;
}

@end
