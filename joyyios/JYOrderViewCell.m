//
//  JYOrderViewCell.m
//  joyyios
//
//  Created by Ping Yang on 4/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYOrderViewCell.h"

const CGFloat kTopMargin = 8.0f;
const CGFloat kLeftMargin = 8.0f;
const CGFloat kRightMargin = 8.0f;
const CGFloat kStartDateButtonWidth = 85.0f;
const CGFloat kStartDateButtonHeight = 85.0f;
const CGFloat kStartTimeButtonWidth = 85.0f;
const CGFloat kStartTimeButtonHeight = 20.0f;
const CGFloat kTitleLabelWidth = 120.0f;
const CGFloat kTitleLabelHeight = 20.0f;
const CGFloat kBodyLabelHeight = 120.0f;
const CGFloat kTimeLabelWidth = 80.0f;
const CGFloat kPlaceLabelWidth = 100.0f;
const CGFloat kDistanceLabelWidth = 80.0f;
const CGFloat kTinyLabelHeight = 20.0f;

@implementation JYOrderViewCell

+ (CGFloat)cellHeight
{
    return kTitleLabelHeight + kBodyLabelHeight + kTinyLabelHeight + kTopMargin;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = FlatWhite;

        [self _createStartDateButton];
        [self _createStartTimeButton];
        [self _createTitleLabel];
        [self _createBodyLabel];
        [self _createPriceLabel];
        [self _createPlaceLabel];
        [self _createDistanceLabel];
        [self _createTimeLabel];
    }
    return self;
}

- (void)setStartDateTime:(NSDate *)date
{
    NSDateFormatter* formatter = [NSDateFormatter new];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter setDateStyle:NSDateFormatterMediumStyle];

    // weekday
    [formatter setDateFormat:@"EEE"];
    self.startDateButton.topTextLabel.text = [formatter stringFromDate:date];

    // day
    [formatter setDateFormat:@"dd"];
    self.startDateButton.textLabel.text = [formatter stringFromDate:date];

    // month name
    [formatter setDateFormat:@"MMM"];
    self.startDateButton.detailTextLabel.text = [formatter stringFromDate:date];

    // time
    [formatter setDateFormat:@"hh:mm a"];
    self.startTimeButton.textLabel.text = [formatter stringFromDate:date];
}

- (void)_createStartDateButton
{
    CGRect frame = CGRectMake(kLeftMargin, kTopMargin, kStartDateButtonWidth, kStartDateButtonHeight);
    self.startDateButton = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleDate appearanceIdentifier:nil];
    self.startDateButton.borderColor = FlatGray;
    self.startDateButton.borderWidth = 1;
    self.startDateButton.contentColor = FlatGrayDark;
    self.startDateButton.cornerRadius = kStartDateButtonWidth / 2;
    self.startDateButton.foregroundColor = ClearColor;

    self.startDateButton.topTextLabel.font = [UIFont systemFontOfSize:10];
    self.startDateButton.textLabel.font = [UIFont systemFontOfSize:25];
    self.startDateButton.detailTextLabel.font = [UIFont systemFontOfSize:10];

    [self addSubview:self.startDateButton];
}

- (void)_createStartTimeButton
{
    CGRect frame = CGRectMake(kLeftMargin, 5 + CGRectGetMaxY(self.startDateButton.frame), kStartTimeButtonWidth, kStartTimeButtonHeight);
    self.startTimeButton = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleDefault appearanceIdentifier:nil];
    self.startTimeButton.contentColor = FlatGrayDark;
    self.startTimeButton.cornerRadius = 4;
    self.startTimeButton.foregroundColor = FlatWhite;
    [self addSubview:self.startTimeButton];
}

- (void)_createTitleLabel
{
    self.titleLabel = [self _createLabel];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
    CGFloat x = kLeftMargin + CGRectGetMaxX(self.startDateButton.frame);
    self.titleLabel.frame = CGRectMake(x, kTopMargin, kTitleLabelWidth, kTitleLabelHeight);
}

- (void)_createPriceLabel
{
    self.priceLabel = [self _createLabel];
    self.priceLabel.font = [UIFont boldSystemFontOfSize:20.0f];
    self.priceLabel.textAlignment = NSTextAlignmentRight;

    CGFloat x = kLeftMargin + CGRectGetMaxX(self.titleLabel.frame);
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - x - kRightMargin;
    self.priceLabel.frame = CGRectMake(x, kTopMargin, width, kTitleLabelHeight);
}

- (void)_createBodyLabel
{
    self.bodyLabel = [self _createLabel];
    self.bodyLabel.font = [UIFont systemFontOfSize:18.0f];
    CGFloat x = kLeftMargin + CGRectGetMaxX(self.startDateButton.frame);
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - x - kRightMargin;
    self.bodyLabel.frame = CGRectMake(x, CGRectGetMaxY(self.titleLabel.frame), width, kBodyLabelHeight);
}

- (void)_createPlaceLabel
{
    self.placeLabel = [self _createLabel];
    self.placeLabel.font = [UIFont systemFontOfSize:14.0f];
    CGFloat x = kLeftMargin;
    CGFloat y = CGRectGetMaxY(self.bodyLabel.frame);
    self.placeLabel.frame = CGRectMake(x, y, kPlaceLabelWidth, kTinyLabelHeight);
}

- (void)_createDistanceLabel
{
    self.distanceLabel = [self _createLabel];
    self.distanceLabel.font = [UIFont systemFontOfSize:14.0f];
    CGFloat x = kLeftMargin + CGRectGetMaxX(self.placeLabel.frame);
    CGFloat y = CGRectGetMaxY(self.bodyLabel.frame);
    self.distanceLabel.frame = CGRectMake(x, y, kDistanceLabelWidth, kTinyLabelHeight);
}

- (void)_createTimeLabel
{
    self.timeLabel = [self _createLabel];
    self.timeLabel.font = [UIFont systemFontOfSize:14.0f];
    CGFloat x = kLeftMargin + CGRectGetMaxX(self.distanceLabel.frame);
    CGFloat y = CGRectGetMaxY(self.bodyLabel.frame);
    self.timeLabel.frame = CGRectMake(x, y, kTimeLabelWidth, kTinyLabelHeight);
}

- (UILabel *)_createLabel
{
    UILabel *label = [UILabel new];
    label.backgroundColor = FlatWhite;
    label.opaque = YES;
    label.textColor = FlatGray;
    label.textAlignment = NSTextAlignmentLeft;
    [self addSubview:label];

    return label;
}
@end
