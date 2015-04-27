//
//  JYOrderViewCell.m
//  joyyios
//
//  Created by Ping Yang on 4/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "JYOrderViewCell.h"

static const CGFloat kTopMargin = 8.0f;
static const CGFloat kLeftMargin = 8.0f;
static const CGFloat kTextLeftMargin = 12.0f;
static const CGFloat kRightMargin = 8.0f;
static const CGFloat kStartDateViewWidth = 70.0f;
static const CGFloat kStartDateViewHeight = 70.0f;
static const CGFloat kStartTimeLabelWidth = 85.0f;
static const CGFloat kStartTimeLabelHeight = 20.0f;
static const CGFloat kTitleLabelWidth = 180.0f;
static const CGFloat kTitleLabelHeight = 25.0f;
static const CGFloat kBodyLabelMinHeight = 53.0f;
static const CGFloat kTimeLabelWidth = 80.0f;
static const CGFloat kCityLabelWidth = 80.0f;
static const CGFloat kDistanceLabelWidth = 50.0f;
static const CGFloat kTinyLabelHeight = 20.0f;

static const CGFloat kFontSizeBody = 18.0f;
static const CGFloat kFontSizeDetail = 13.0f;

@interface JYOrderViewCell ()

@property(nonatomic) JYDateView *startDateView;
@property(nonatomic) UILabel *startTimeLabel;
@property(nonatomic) UILabel *timeLabel;
@property(nonatomic) UILabel *distanceLabel;

@end


@implementation JYOrderViewCell

+ (CGFloat)cellHeightForText:(NSString *)text
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

    return  kTopMargin + kTitleLabelHeight + bodyLabelHeight + kTinyLabelHeight;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = [UIColor whiteColor];

        [self _createStartDateView];
        [self _createStartTimeLabel];
        [self _createTitleLabel];
        [self _createBodyLabel];
        [self _createPriceLabel];
        [self _createCityLabel];
        [self _createDistanceLabel];
        [self _createTimeLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.bodyLabel.height = self.height - (kTopMargin + kTitleLabelHeight + kTinyLabelHeight);
    self.cityLabel.y = CGRectGetMaxY(self.bodyLabel.frame);
    self.distanceLabel.y = self.cityLabel.y;
    self.timeLabel.y = self.cityLabel.y;
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

- (void)setCreateTime:(NSString *)dateString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    NSDate *createDate = [dateFormatter dateFromString:dateString];

    NSDate *now = [NSDate date];
    NSTimeInterval secondsBetween = [now timeIntervalSinceDate:createDate];

    NSString *ago = NSLocalizedString(@"ago", nil);
    int numberOfDays = secondsBetween / 86400;
    if (numberOfDays > 0)
    {
        NSString *days = (numberOfDays == 1) ? NSLocalizedString(@"day", nil) : NSLocalizedString(@"days", nil);

        self.timeLabel.text = [NSString stringWithFormat:@"%d %@ %@", numberOfDays, days, ago];
        return;
    }

    int numberOfHours = secondsBetween / 3600;
    if (numberOfHours > 0)
    {
        NSString *hours = (numberOfHours == 1) ? NSLocalizedString(@"hour", nil) : NSLocalizedString(@"hours", nil);

        self.timeLabel.text = [NSString stringWithFormat:@"%d %@ %@", numberOfHours, hours, ago];
        return;
    }

    int numberOfMinutes = secondsBetween / 60;
    if (numberOfMinutes > 0)
    {
        NSString *minutes = (numberOfMinutes == 1) ? NSLocalizedString(@"min", nil) : NSLocalizedString(@"mins", nil);

        self.timeLabel.text = [NSString stringWithFormat:@"%d %@ %@", numberOfMinutes, minutes, ago];
        return;
    }

    int numberOfSeconds = (int)secondsBetween;
    NSString *seconds = (numberOfSeconds == 1) ? NSLocalizedString(@"sec", nil) : NSLocalizedString(@"secs", nil);
    self.timeLabel.text = [NSString stringWithFormat:@"%d %@ %@", numberOfSeconds, seconds, ago];
}

- (void)setDistanceFromPoint:(CLLocationCoordinate2D )point
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    if (!appDelegate.currentLocation)
    {
        return;
    }

    CLLocation *pointLocation = [[CLLocation alloc] initWithCoordinate: point altitude:1 horizontalAccuracy:1 verticalAccuracy:-1 timestamp:nil];

    CLLocationDistance kilometers = [appDelegate.currentLocation distanceFromLocation:pointLocation] / 1000;
    NSUInteger numberOfMiles = (NSUInteger)kilometers * 0.621371;
    if (numberOfMiles == 0)
    {
        numberOfMiles = 1;
    }

    NSString *miles = (numberOfMiles == 1) ? NSLocalizedString(@"mile", nil) : NSLocalizedString(@"miles", nil);
    self.distanceLabel.text = [NSString stringWithFormat:@"%tu %@", numberOfMiles, miles];
}

- (void)_createStartDateView
{
    CGRect frame = CGRectMake(kLeftMargin, kTopMargin, kStartDateViewWidth, kStartDateViewHeight);
    self.startDateView = [[JYDateView alloc] initWithFrame:frame];

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

- (void)_createCityLabel
{
    self.cityLabel = [self _createLabel];
    self.cityLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
    CGFloat x = kTextLeftMargin + CGRectGetMaxX(self.startDateView.frame);
    CGFloat y = CGRectGetMaxY(self.bodyLabel.frame);
    self.cityLabel.frame = CGRectMake(x, y, kCityLabelWidth, kTinyLabelHeight);
    self.cityLabel.textColor = FlatGrayDark;
}

- (void)_createDistanceLabel
{
    self.distanceLabel = [self _createLabel];
    self.distanceLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
    CGFloat x = kLeftMargin + CGRectGetMaxX(self.cityLabel.frame);
    CGFloat y = CGRectGetMaxY(self.bodyLabel.frame);
    self.distanceLabel.frame = CGRectMake(x, y, kDistanceLabelWidth, kTinyLabelHeight);
    self.distanceLabel.textColor = FlatGrayDark;
}

- (void)_createTimeLabel
{
    self.timeLabel = [self _createLabel];
    self.timeLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
    CGFloat x = kLeftMargin + CGRectGetMaxX(self.distanceLabel.frame);
    CGFloat y = CGRectGetMaxY(self.bodyLabel.frame);
    self.timeLabel.frame = CGRectMake(x, y, kTimeLabelWidth, kTinyLabelHeight);
    self.timeLabel.textColor = FlatGrayDark;
}

- (UILabel *)_createLabel
{
    UILabel *label = [UILabel new];
    label.backgroundColor = [UIColor whiteColor];
    label.opaque = YES;
    label.font = [UIFont systemFontOfSize:kFontSizeBody];
    label.textColor = FlatBlack;
    label.textAlignment = NSTextAlignmentLeft;
    [self addSubview:label];

    return label;
}

@end
