//
//  JYOrderItemView.m
//  joyyios
//
//  Created by Ping Yang on 4/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYOrderItemView.h"

static const CGFloat kBodyLabelMinHeight = 53.0f;
static const CGFloat kFontSizeBody = 18.0f;
static const CGFloat kLeftMargin = 8.0f;
static const CGFloat kRightMargin = 8.0f;
static const CGFloat kStartDateViewWidth = 70.0f;
static const CGFloat kStartDateViewHeight = 70.0f;
static const CGFloat kStartTimeLabelWidth = 85.0f;
static const CGFloat kStartTimeLabelHeight = 20.0f;
static const CGFloat kTextLeftMargin = 12.0f;
static const CGFloat kTinyLabelHeight = 20.0f;
static const CGFloat kTitleLabelWidth = 180.0f;
static const CGFloat kTitleLabelHeight = 25.0f;
static const CGFloat kTopMargin = 8.0f;

@interface JYOrderItemView ()

@property(nonatomic) JYDateView *startDateView;
@property(nonatomic) UILabel *startTimeLabel;
@property(nonatomic) UILabel *timeLabel;
@property(nonatomic) UILabel *distanceLabel;

@end


@implementation JYOrderItemView

+ (CGFloat)viewHeightForText:(NSString *)text
{
    CGFloat bodyLabelX = kTextLeftMargin + kLeftMargin + kStartDateViewWidth;
    CGFloat bodyLabelWidth = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - bodyLabelX - kRightMargin;
    CGSize maximumSize = CGSizeMake(bodyLabelWidth, 10000);

    static UILabel *dummyLabel = nil;
    if (!dummyLabel)
    {
        dummyLabel = [UILabel new];
        dummyLabel.font = [UIFont systemFontOfSize:kFontSizeBody];
        dummyLabel.numberOfLines = 0;
        dummyLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    dummyLabel.text = text;
    CGSize expectSize = [dummyLabel sizeThatFits:maximumSize];
    CGFloat bodyLabelHeight = fmax(expectSize.height, kBodyLabelMinHeight);

    return kTopMargin + kTitleLabelHeight + bodyLabelHeight + kTinyLabelHeight;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = FlatWhite;

        [self _createStartDateView];
        [self _createStartTimeLabel];
        [self _createTitleLabel];
        [self _createBodyLabel];
        [self _createPriceLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.bodyLabel.height = self.height - (kTopMargin + kTitleLabelHeight);
}

- (void)setStartDateTime:(NSDate *)date
{
    NSDateFormatter* dateFormatter = [NSDateFormatter new];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];

    // weekday
    [dateFormatter setDateFormat:@"EEE"];
    self.startDateView.topLabel.text = [dateFormatter stringFromDate:date];

    // day
    [dateFormatter setDateFormat:@"dd"];
    self.startDateView.centerLabel.text = [dateFormatter stringFromDate:date];

    // month name
    [dateFormatter setDateFormat:@"MMM"];
    self.startDateView.bottomLabel.text = [dateFormatter stringFromDate:date];

    // time
    [dateFormatter setDateFormat:@"hh:mm a"];
    self.startTimeLabel.text = [dateFormatter stringFromDate:date];
}

- (void)_createStartDateView
{
    CGRect frame = CGRectMake(kLeftMargin, kTopMargin, kStartDateViewWidth, kStartDateViewHeight);
    self.startDateView = [[JYDateView alloc] initWithFrame:frame];
    self.startDateView.viewColor = FlatWhite;

    [self addSubview:self.startDateView];
}

- (void)_createStartTimeLabel
{
    CGRect frame = CGRectMake(0, kTopMargin + CGRectGetMaxY(self.startDateView.frame), kStartTimeLabelWidth, kStartTimeLabelHeight);
    self.startTimeLabel = [[UILabel alloc] initWithFrame:frame];
    self.startTimeLabel.centerX = self.startDateView.centerX;
    self.startTimeLabel.font = [UIFont systemFontOfSize:15.0f];
    self.startTimeLabel.textColor = FlatGrayDark;
    self.startTimeLabel.textAlignment = NSTextAlignmentCenter;
    self.startTimeLabel.backgroundColor = FlatWhite;

    [self addSubview:self.startTimeLabel];
}

- (void)_createTitleLabel
{
    self.titleLabel = [self _createLabel];
    CGFloat x = kTextLeftMargin + CGRectGetMaxX(self.startDateView.frame);
    self.titleLabel.frame = CGRectMake(x, kTopMargin, kTitleLabelWidth, kTitleLabelHeight);
}

- (void)_createPriceLabel
{
    self.priceLabel = [self _createLabel];
    self.priceLabel.textAlignment = NSTextAlignmentRight;

    CGFloat x = kTextLeftMargin + CGRectGetMaxX(self.titleLabel.frame);
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - x - kRightMargin;
    self.priceLabel.frame = CGRectMake(x, kTopMargin, width, kTitleLabelHeight);
}

- (void)_createBodyLabel
{
    self.bodyLabel = [self _createLabel];
    CGFloat x = kTextLeftMargin + CGRectGetMaxX(self.startDateView.frame);
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - x - kRightMargin;
    CGFloat height = kBodyLabelMinHeight;

    self.bodyLabel.frame = CGRectMake(x, CGRectGetMaxY(self.titleLabel.frame), width, height);
    self.bodyLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.bodyLabel.numberOfLines = 0;
}

- (UILabel *)_createLabel
{
    UILabel *label = [UILabel new];
    label.backgroundColor = FlatWhite;
    label.opaque = YES;
    label.font = [UIFont systemFontOfSize:kFontSizeBody];
    label.textColor = FlatBlack;
    label.textAlignment = NSTextAlignmentLeft;
    [self addSubview:label];
    
    return label;
}

@end
