//
//  JYOrderCard.m
//  joyyios
//
//  Created by Ping Yang on 4/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "JYDateView.h"
#import "JYOrderCard.h"

static const CGFloat kAddressLabelHeight = 30.0f;
static const CGFloat kBidLabelHeight = 30.0f;
static const CGFloat kBodyLabelMinHeight = 53.0f;
static const CGFloat kCityLabelWidth = 80.0f;
static const CGFloat kDistanceLabelWidth = 35.0f;
static const CGFloat kFontSizeAddress = 15.0f;
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

@interface JYOrderCard ()

@property(nonatomic) BOOL addressLabelHidden;
@property(nonatomic) BOOL bidLabelHidden;

@property(nonatomic, weak) JYDateView *startDateView;
@property(nonatomic, weak) UILabel *bidLabel;
@property(nonatomic, weak) UILabel *bodyLabel;
@property(nonatomic, weak) UILabel *cityLabel;
@property(nonatomic, weak) UILabel *distanceLabel;
@property(nonatomic, weak) UILabel *priceLabel;
@property(nonatomic, weak) UILabel *startTimeLabel;
@property(nonatomic, weak) UILabel *timeLabel;
@property(nonatomic, weak) UILabel *titleLabel;
@property(nonatomic, weak) UILabel *addressLabel;
@property(nonatomic, weak) UILabel *fromLabel;

@end


@implementation JYOrderCard

+ (CGFloat)bodyLabelHeightForText:(NSString *)text
{
    CGFloat bodyLabelX = kTextLeftMargin + kMarginLeft + kStartDateViewWidth;
    CGFloat bodyLabelWidth = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - bodyLabelX - kMarginRight;
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

+ (CGFloat)heightForOrder:(JYInvite *)order withAddress:(BOOL)showAddress andBid:(BOOL)showBid
{
    CGFloat height = [JYOrderCard bodyLabelHeightForText:order.note];
    height += kTopMargin + kTitleLabelHeight + kTinyLabelHeight;

    // address
    if (showAddress)
    {
        height += showAddress ? kAddressLabelHeight : 0;
    }

    // bid
    if (showBid)
    {
        height += (order.bids.count > 0) ? kBidLabelHeight : 0;
    }

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
    self.backgroundColor = JoyyWhite;

    self.addressLabelHidden = YES;
    self.bidLabelHidden = YES;
    self.tinyLabelsHidden = NO;

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
    [self _createAddressLabel];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.bodyLabel.height = self.height - (kTopMargin + kTitleLabelHeight + kTinyLabelHeight);

    self.bidLabel.height = self.bidLabelHidden ? 0 : kBidLabelHeight;
    self.fromLabel.height = self.addressLabel.height = self.addressLabelHidden ? 0 : kAddressLabelHeight;

    self.bodyLabel.height -= (self.bidLabel.height + self.addressLabel.height);

    if (self.tinyLabelsHidden)
    {
        self.cityLabel.height = self.distanceLabel.height = self.timeLabel.height = self.commentsLabel.height = 0;
        self.bidLabel.y = CGRectGetMaxY(self.bodyLabel.frame);
    }
    else
    {
        self.cityLabel.y = self.distanceLabel.y = self.timeLabel.y = self.commentsLabel.y = CGRectGetMaxY(self.bodyLabel.frame);
        self.cityLabel.height = self.distanceLabel.height = self.timeLabel.height = self.commentsLabel.height = kTinyLabelHeight;
        self.bidLabel.y = CGRectGetMaxY(self.cityLabel.frame);
    }

    self.fromLabel.y = self.addressLabel.y = CGRectGetMaxY(self.bidLabel.frame);
}

- (void)presentOrder:(JYInvite *)order withAddress:(BOOL)showAddress andBid:(BOOL)showBid
{
    self.bidLabelHidden = !showBid;
    self.addressLabelHidden = !showAddress;

    [self _setStartDateTime:[NSDate dateWithTimeIntervalSinceReferenceDate:order.startTime]];

    self.priceLabel.text = order.priceString;
    self.timeLabel.text = order.createTimeString;

    // distance
    CLLocationCoordinate2D point = CLLocationCoordinate2DMake(order.lat, order.lon);
    [self _setDistanceFromPoint:point];

    self.titleLabel.text = order.title;
    self.bodyLabel.text = order.note;
    self.cityLabel.text = order.city;

    if (showBid && order.bids.count > 0)
    {
        JYBid *bid = [order.bids lastObject];
        if (bid.status == JYBidStatusActive)
        {
            NSString *bidPrefix = NSLocalizedString(@"You asked for", nil);
            self.bidLabel.text = [NSString stringWithFormat:@"%@ %@     %@", bidPrefix, bid.priceString, bid.expireTimeString];
        }
        else
        {
            NSString *bidPrefix = NSLocalizedString(@"The customer accepted your bid at ", nil);
            self.bidLabel.text = [NSString stringWithFormat:@"%@ %@", bidPrefix, bid.priceString];
        }
    }

    if (showAddress)
    {
        self.fromLabel.text = NSLocalizedString(@"Addr:", nil);
        self.addressLabel.text = order.address;
    }
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
    CGRect frame = CGRectMake(kMarginLeft, kTopMargin, kStartDateViewWidth, kStartDateViewHeight);
    JYDateView *startDateView = [[JYDateView alloc] initWithFrame:frame];
    startDateView.userInteractionEnabled = NO;
    self.startDateView = startDateView;
    [self addSubview:self.startDateView];
}

- (void)_createStartTimeLabel
{
    CGRect frame = CGRectMake(0, kTopMargin + CGRectGetMaxY(self.startDateView.frame), kStartTimeLabelWidth, kStartTimeLabelHeight);
    UILabel *startTimeLabel = [[UILabel alloc] initWithFrame:frame];
    startTimeLabel.centerX = self.startDateView.centerX;
    startTimeLabel.font = [UIFont systemFontOfSize:15.0f];
    startTimeLabel.textColor = FlatGrayDark;
    startTimeLabel.textAlignment = NSTextAlignmentCenter;

    self.startTimeLabel = startTimeLabel;
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
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - x - kMarginRight;
    self.priceLabel.frame = CGRectMake(x, kTopMargin, width, kTitleLabelHeight);
}

- (void)_createBodyLabel
{
    self.bodyLabel = [self _createLabel];
    CGFloat x = kTextLeftMargin + CGRectGetMaxX(self.startDateView.frame);
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - x - kMarginRight;
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
    CGFloat x = kMarginLeft + CGRectGetMaxX(self.cityLabel.frame);
    self.distanceLabel.frame = CGRectMake(x, 0, kDistanceLabelWidth, kTinyLabelHeight);
    self.distanceLabel.textColor = FlatGrayDark;
}

- (void)_createTimeLabel
{
    self.timeLabel = [self _createLabel];
    self.timeLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
    CGFloat x = kMarginLeft + CGRectGetMaxX(self.distanceLabel.frame);
    self.timeLabel.frame = CGRectMake(x, 0, kTimeLabelWidth, kTinyLabelHeight);
    self.timeLabel.textColor = FlatGrayDark;
}

- (void)_createCommentsLabel
{
    self.commentsLabel = [self _createLabel];
    self.commentsLabel.textAlignment = NSTextAlignmentRight;
    self.commentsLabel.font = [UIFont systemFontOfSize:kFontSizeDetail];
    CGFloat x = kMarginLeft + CGRectGetMaxX(self.timeLabel.frame);
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - x - kMarginRight;
    self.commentsLabel.frame = CGRectMake(x, 0, width, kTinyLabelHeight);
    self.commentsLabel.textColor = FlatGrayDark;
}

- (void)_createbidLabel
{
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - kTextLeftMargin - kMarginRight;

    self.bidLabel = [self _createLabel];
    self.bidLabel.frame = CGRectMake(kTextLeftMargin, 0, width, kBidLabelHeight);
    self.bidLabel.textAlignment = NSTextAlignmentRight;
    self.bidLabel.font = [UIFont systemFontOfSize:kFontSizeAddress];
}

- (void)_createAddressLabel
{
    self.fromLabel = [self _createLabel];
    self.fromLabel.frame = CGRectMake(kTextLeftMargin, 0, 35, kAddressLabelHeight);
    self.fromLabel.font = [UIFont systemFontOfSize:kFontSizeAddress];

    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - kTextLeftMargin - kMarginRight;

    self.addressLabel = [self _createLabel];
    self.addressLabel.frame = CGRectMake(kTextLeftMargin, 0, width, kAddressLabelHeight);
    self.addressLabel.font = [UIFont boldSystemFontOfSize:kFontSizeAddress];
    self.addressLabel.textAlignment = NSTextAlignmentRight;
}

- (UILabel *)_createLabel
{
    UILabel *label = [UILabel new];
    label.font = [UIFont systemFontOfSize:kFontSizeBody];
    label.textColor = FlatBlack;
    label.textAlignment = NSTextAlignmentLeft;
    label.userInteractionEnabled = NO;

    [self addSubview:label];
    
    return label;
}

@end
