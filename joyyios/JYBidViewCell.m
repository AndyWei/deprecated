//
//  JYBidViewCell.m
//  joyyios
//
//  Created by Ping Yang on 4/25/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYBidViewCell.h"

static const CGFloat kBidderNameLabelHeight = 40;
static const CGFloat kBidderNameLabelWidth = 80;
static const CGFloat kLabelHeight = 60.0f;
static const CGFloat kLeftMargin = 8.0f;
static const CGFloat kRightMargin = 8.0f;
static const CGFloat kTopMargin = 8.0f;

@interface JYBidViewCell ()

@property(nonatomic) UILabel *expireTimeLabel;

@end


@implementation JYBidViewCell


+ (CGFloat)cellHeight
{
    return kTopMargin + kLabelHeight;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = [UIColor whiteColor];

        [self _createBidderNameLabel];
        [self _createExpireTimeLabel];
        [self _createPriceLabel];
    }
    return self;
}

- (void)setExpireTime:(NSTimeInterval)expireAt
{
    NSDate *expireTime = [NSDate dateWithTimeIntervalSinceReferenceDate:expireAt];
    NSTimeInterval secondsBetween = [expireTime timeIntervalSinceNow];

    NSString *expireString = NSLocalizedString(@"Expire In", nil);
    int numberOfDays = secondsBetween / 86400;
    if (numberOfDays > 0)
    {
        NSString *days = (numberOfDays == 1) ? NSLocalizedString(@"day", nil) : NSLocalizedString(@"days", nil);

        self.expireTimeLabel.text = [NSString stringWithFormat:@"%@ %d %@", expireString, numberOfDays, days];
        return;
    }

    int numberOfHours = secondsBetween / 3600;
    if (numberOfHours > 0)
    {
        NSString *hours = (numberOfHours == 1) ? NSLocalizedString(@"hour", nil) : NSLocalizedString(@"hours", nil);

        self.expireTimeLabel.text = [NSString stringWithFormat:@"%@ %d %@", expireString, numberOfHours, hours];
        return;
    }

    int numberOfMinutes = secondsBetween / 60;
    if (numberOfMinutes > 0)
    {
        NSString *minutes = (numberOfMinutes == 1) ? NSLocalizedString(@"min", nil) : NSLocalizedString(@"mins", nil);

        self.expireTimeLabel.text = [NSString stringWithFormat:@"%@ %d %@", expireString, numberOfMinutes, minutes];
        return;
    }

    int numberOfSeconds = (int)secondsBetween;
    NSString *seconds = (numberOfSeconds == 1) ? NSLocalizedString(@"sec", nil) : NSLocalizedString(@"secs", nil);
    self.expireTimeLabel.text = [NSString stringWithFormat:@"%@ %d %@", expireString, numberOfSeconds, seconds];
}

- (void)setRatingTotalScore:(NSUInteger)score count:(NSUInteger)count
{
}


- (void)_createBidderNameLabel
{
    CGRect frame = CGRectMake(0, kTopMargin, kBidderNameLabelWidth, kBidderNameLabelHeight);
    self.bidderNameLabel = [[UILabel alloc] initWithFrame:frame];
    self.bidderNameLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.bidderNameLabel];
}

- (void)_createExpireTimeLabel
{
    self.expireTimeLabel = [self _createLabel];
    CGFloat x = kLeftMargin + CGRectGetMaxX(self.bidderNameLabel.frame);
    self.expireTimeLabel.frame = CGRectMake(x, kTopMargin, 200, kLabelHeight);
}

- (void)_createPriceLabel
{
    self.priceLabel = [self _createLabel];
    self.priceLabel.textAlignment = NSTextAlignmentRight;

    CGFloat x = CGRectGetMaxX(self.expireTimeLabel.frame);
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - x - kRightMargin;
    self.priceLabel.frame = CGRectMake(x, kTopMargin, width, kLabelHeight);
}

- (UILabel *)_createLabel
{
    UILabel *label = [UILabel new];
    label.backgroundColor = [UIColor whiteColor];
    label.opaque = YES;
    label.font = [UIFont systemFontOfSize:18.0f];
    label.textColor = FlatBlack;
    label.textAlignment = NSTextAlignmentLeft;
    [self addSubview:label];
    
    return label;
}

@end
