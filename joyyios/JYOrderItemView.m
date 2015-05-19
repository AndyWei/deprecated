//
//  JYOrderItemView.m
//  joyyios
//
//  Created by Ping Yang on 4/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "JYDateView.h"
#import "JYOrderItemView.h"

static const CGFloat kBidLabelHeight = 40.0f;
static const CGFloat kBodyLabelMinHeight = 53.0f;
static const CGFloat kCityLabelWidth = 80.0f;
static const CGFloat kDistanceLabelWidth = 35.0f;
static const CGFloat kFontSizeBody = 18.0f;
static const CGFloat kFontSizeDetail = 13.0f;
static const CGFloat kLeftMargin = 8.0f;
static const CGFloat kRightMargin = 8.0f;
static const CGFloat kStartDateViewWidth = 70.0f;
static const CGFloat kStartDateViewHeight = 70.0f;
static const CGFloat kStartTimeLabelWidth = 85.0f;
static const CGFloat kStartTimeLabelHeight = 20.0f;
static const CGFloat kTextLeftMargin = 12.0f;
static const CGFloat kTimeLabelWidth = 70.0f;
static const CGFloat kTinyLabelHeight = 20.0f;
static const CGFloat kTitleLabelWidth = 180.0f;
static const CGFloat kTitleLabelHeight = 25.0f;
static const CGFloat kTopMargin = 8.0f;

@interface JYOrderItemView ()

@property(nonatomic) JYDateView *startDateView;
@property(nonatomic) UILabel *bidLabel;
@property(nonatomic) UILabel *bodyLabel;
@property(nonatomic) UILabel *cityLabel;
@property(nonatomic) UILabel *distanceLabel;
@property(nonatomic) UILabel *priceLabel;
@property(nonatomic) UILabel *startTimeLabel;
@property(nonatomic) UILabel *timeLabel;
@property(nonatomic) UILabel *titleLabel;
@property(nonatomic) UIView *bidBackground;

@end


@implementation JYOrderItemView

+ (CGFloat)bodyLabelHeightForText:(NSString *)text
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

    return bodyLabelHeight;
}

+ (CGFloat)viewHeightForText:(NSString *)text
{
    CGFloat bodyLabelHeight = [JYOrderItemView bodyLabelHeightForText:text];

    return kTopMargin + kTitleLabelHeight + bodyLabelHeight + kTinyLabelHeight;
}

+ (CGFloat)viewHeightForText:(NSString *)text withBid:(BOOL)bidded
{
    CGFloat height = [JYOrderItemView viewHeightForText:text];
    height += bidded ? kBidLabelHeight : 0;
    return height;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit
{
    self.opaque = YES;
    self.backgroundColor = FlatWhite;
    self.tinyLabelsHidden = NO;
    self.bidLabelHidden = YES;

    [self _createStartDateView];
    [self _createStartTimeLabel];
    [self _createTitleLabel];
    [self _createBodyLabel];
    [self _createPriceLabel];
    [self _createCityLabel];
    [self _createDistanceLabel];
    [self _createTimeLabel];
    [self _createCommentsLabel];
    [self _createbidLabel];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.bodyLabel.height = self.height - (kTopMargin + kTitleLabelHeight + kTinyLabelHeight);

    CGFloat bidLabelHeight = self.bidLabelHidden ? 0 : kBidLabelHeight;
    self.bodyLabel.height -= bidLabelHeight;
    self.bidBackground.height = self.bidLabel.height = bidLabelHeight;

    if (self.tinyLabelsHidden)
    {
        self.cityLabel.height = self.distanceLabel.height = self.timeLabel.height = self.commentsLabel.height = 0;
        self.bidBackground.y = CGRectGetMaxY(self.bodyLabel.frame);
    }
    else
    {
        self.cityLabel.y = self.distanceLabel.y = self.timeLabel.y = self.commentsLabel.y = CGRectGetMaxY(self.bodyLabel.frame);
        self.cityLabel.height = self.distanceLabel.height = self.timeLabel.height = self.commentsLabel.height = kTinyLabelHeight;
        self.bidBackground.y = CGRectGetMaxY(self.cityLabel.frame);
    }
}

- (void)setViewColor:(UIColor *)color
{
    if (color == _viewColor)
    {
        return;
    }

    self.backgroundColor = _viewColor = color;
    self.titleLabel.backgroundColor = self.bodyLabel.backgroundColor = self.priceLabel.backgroundColor = color;
    self.cityLabel.backgroundColor = self.timeLabel.backgroundColor = self.distanceLabel.backgroundColor = color;
    self.startDateView.viewColor = self.startTimeLabel.backgroundColor = self.commentsLabel.backgroundColor = color;
}

- (void)presentOrder:(NSDictionary *)order
{
    // start date and time
    NSTimeInterval startTime = [[order objectForKey:@"starttime"] integerValue];

    [self _setStartDateTime:[NSDate dateWithTimeIntervalSinceReferenceDate:startTime]];

    // price
    NSUInteger price = [[order objectForKey:@"price"] unsignedIntegerValue];
    self.priceLabel.text = [NSString stringWithFormat:@"$%tu", price];

    // create time
    [self _setCreateTime:[order objectForKey:@"created_at"]];

    // distance
    CLLocationDegrees lat = [[order objectForKey:@"startpointlat"] doubleValue];
    CLLocationDegrees lon = [[order objectForKey:@"startpointlon"] doubleValue];
    CLLocationCoordinate2D point = CLLocationCoordinate2DMake(lat, lon);
    [self _setDistanceFromPoint:point];

    self.titleLabel.text = [order objectForKey:@"title"];
    self.bodyLabel.text = [order objectForKey:@"note"];
    self.cityLabel.text = [order objectForKey:@"startcity"];
    self.bidLabel.height = self.bidLabelHidden ? 0 : kBidLabelHeight;
}

- (void)presentOrder:(NSDictionary *)order andBid:(NSDictionary *)bid
{
    [self presentOrder:order];
    NSUInteger bidPrice = [[bid objectForKey:@"price"] unsignedIntegerValue];
    NSString *bidPrefix = NSLocalizedString(@"You asked for", nil);
    self.bidLabel.text = [NSString stringWithFormat:@"%@ $%tu  ", bidPrefix, bidPrice];
    self.bidLabel.backgroundColor = FlatLime;
}

- (void)_setStartDateTime:(NSDate *)date
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

- (void)_setCreateTime:(NSString *)dateString
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
        NSString *days = NSLocalizedString(@"d", nil);

        self.timeLabel.text = [NSString stringWithFormat:@"%d %@ %@", numberOfDays, days, ago];
        return;
    }

    int numberOfHours = secondsBetween / 3600;
    if (numberOfHours > 0)
    {
        NSString *hours = NSLocalizedString(@"h", nil);

        self.timeLabel.text = [NSString stringWithFormat:@"%d %@ %@", numberOfHours, hours, ago];
        return;
    }

    int numberOfMinutes = secondsBetween / 60;
    if (numberOfMinutes > 0)
    {
        NSString *minutes = NSLocalizedString(@"m", nil);

        self.timeLabel.text = [NSString stringWithFormat:@"%d %@ %@", numberOfMinutes, minutes, ago];
        return;
    }

    int numberOfSeconds = (int)secondsBetween;
    NSString *seconds = NSLocalizedString(@"s", nil);
    self.timeLabel.text = [NSString stringWithFormat:@"%d %@ %@", numberOfSeconds, seconds, ago];
}

- (void)_setDistanceFromPoint:(CLLocationCoordinate2D )point
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:appDelegate.currentCoordinate.latitude longitude:appDelegate.currentCoordinate.longitude];

    CLLocation *pointLocation = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];

    CLLocationDistance kilometers = [currentLocation distanceFromLocation:pointLocation] / 1000;
    NSUInteger numberOfMiles = (NSUInteger)kilometers * 0.621371;
    if (numberOfMiles == 0)
    {
        numberOfMiles = 1;
    }

    NSString *miles = NSLocalizedString(@"mi", nil);
    self.distanceLabel.text = [NSString stringWithFormat:@"%tu %@", numberOfMiles, miles];
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

- (void)_createCityLabel
{
    self.cityLabel = [self _createLabel];
    self.cityLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
    CGFloat x = kTextLeftMargin + CGRectGetMaxX(self.startDateView.frame);
    self.cityLabel.frame = CGRectMake(x, 0, kCityLabelWidth, kTinyLabelHeight);
    self.cityLabel.textColor = FlatGrayDark;
}

- (void)_createDistanceLabel
{
    self.distanceLabel = [self _createLabel];
    self.distanceLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
    CGFloat x = kLeftMargin + CGRectGetMaxX(self.cityLabel.frame);
    self.distanceLabel.frame = CGRectMake(x, 0, kDistanceLabelWidth, kTinyLabelHeight);
    self.distanceLabel.textColor = FlatGrayDark;
}

- (void)_createTimeLabel
{
    self.timeLabel = [self _createLabel];
    self.timeLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
    CGFloat x = kLeftMargin + CGRectGetMaxX(self.distanceLabel.frame);
    self.timeLabel.frame = CGRectMake(x, 0, kTimeLabelWidth, kTinyLabelHeight);
    self.timeLabel.textColor = FlatGrayDark;
}

- (void)_createCommentsLabel
{
    self.commentsLabel = [self _createLabel];
    self.commentsLabel.textAlignment = NSTextAlignmentRight;
    self.commentsLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
    CGFloat x = kLeftMargin + CGRectGetMaxX(self.timeLabel.frame);
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - x - kRightMargin;
    self.commentsLabel.frame = CGRectMake(x, 0, width, kTinyLabelHeight);
    self.commentsLabel.textColor = FlatGrayDark;
}

- (void)_createbidLabel
{
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]);
    self.bidBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, kBidLabelHeight)];
    self.bidBackground.backgroundColor = FlatLime;
    self.bidBackground.opaque = YES;

    self.bidLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width - kRightMargin, kBidLabelHeight)];
    self.bidLabel.font = [UIFont systemFontOfSize:kFontSizeBody];
    self.bidLabel.textAlignment = NSTextAlignmentRight;
    self.bidLabel.textColor = FlatBlack;
    self.bidLabel.opaque = YES;

    [self.bidBackground addSubview:self.bidLabel];
    [self addSubview:self.bidBackground];
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
