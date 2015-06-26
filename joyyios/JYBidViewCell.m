//
//  JYBidViewCell.m
//  joyyios
//
//  Created by Ping Yang on 4/25/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AXRatingView/AXRatingView.h>

#import "JYBidViewCell.h"

static const CGFloat kBidderNameLabelHeight = 35;
static const CGFloat kBidderNameLabelWidth = 150;
static const CGFloat kLabelHeight = 60.0f;
static const CGFloat kRatingViewHeight = 20;
static const CGFloat kRatingViewWidth = 70;
static const CGFloat kTinyFontSize = 13.0f;

@interface JYBidViewCell ()

@property(nonatomic, weak) AXRatingView *ratingView;
@property(nonatomic, weak) UILabel *bidderNameLabel;
@property(nonatomic, weak) UILabel *priceLabel;
@property(nonatomic, weak) UILabel *expireTimeLabel;
@property(nonatomic, weak) UILabel *ratingCountLabel;

@end


@implementation JYBidViewCell


+ (CGFloat)cellHeight
{
    return kMarginTop + kLabelHeight;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = JoyyWhite;

        [self _createBidderNameLabel];
        [self _createRatingView];
        [self _createRatingCountLabel];
        [self _createExpireTimeLabel];
        [self _createPriceLabel];
    }
    return self;
}

- (void)presentBid:(JYBid *)bid
{
    self.bidderNameLabel.text = bid.username;
    self.expireTimeLabel.text = bid.expireTimeString;
    self.priceLabel.text = bid.priceString;

    [self setRatingTotalScore:bid.userRatingTotal count:bid.userRatingCount];
}

- (void)setRatingTotalScore:(CGFloat)score count:(NSUInteger)count
{
    self.ratingView.value = (count == 0) ? 0 : score/count;
    self.ratingCountLabel.text = [NSString stringWithFormat:@"(%tu)", count];
}

- (void)_createBidderNameLabel
{
    self.bidderNameLabel = [self _createLabel];
    self.bidderNameLabel.frame = CGRectMake(kMarginLeft + 5, kMarginTop, kBidderNameLabelWidth, kBidderNameLabelHeight);
    self.bidderNameLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)_createRatingView
{
    CGFloat y = CGRectGetMaxY(self.bidderNameLabel.frame);
    CGRect frame = CGRectMake(kMarginLeft, y, kRatingViewWidth, kRatingViewHeight);

    AXRatingView *ratingView = [[AXRatingView alloc] initWithFrame:frame];
    ratingView.markFont = [UIFont systemFontOfSize:kTinyFontSize];
    [ratingView setStepInterval:0.5];
    ratingView.userInteractionEnabled = NO;
    self.ratingView = ratingView;

    [self addSubview:self.ratingView];
}

- (void)_createRatingCountLabel
{
    CGFloat x = CGRectGetMaxX(self.ratingView.frame);
    CGFloat y = CGRectGetMaxY(self.bidderNameLabel.frame);
    self.ratingCountLabel = [self _createLabel];
    self.ratingCountLabel.frame = CGRectMake(x, y, kBidderNameLabelWidth - kRatingViewWidth, kRatingViewHeight);
    self.ratingCountLabel.font = [UIFont systemFontOfSize:kTinyFontSize];
}

- (void)_createExpireTimeLabel
{
    self.expireTimeLabel = [self _createLabel];
    CGFloat x = kMarginLeft + CGRectGetMaxX(self.bidderNameLabel.frame);
    self.expireTimeLabel.frame = CGRectMake(x, CGRectGetMaxY(self.bidderNameLabel.frame), 120, kRatingViewHeight);
    self.expireTimeLabel.font = [UIFont systemFontOfSize:kTinyFontSize];
}

- (void)_createPriceLabel
{
    self.priceLabel = [self _createLabel];
    self.priceLabel.textAlignment = NSTextAlignmentRight;

    CGFloat x = CGRectGetMaxX(self.expireTimeLabel.frame);
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - x - kMarginRight;
    self.priceLabel.frame = CGRectMake(x, kMarginTop, width, kLabelHeight);
}

- (UILabel *)_createLabel
{
    UILabel *label = [UILabel new];
    label.backgroundColor = ClearColor;
    label.font = [UIFont systemFontOfSize:22.0f];
    label.textColor = FlatBlack;
    label.textAlignment = NSTextAlignmentLeft;
    [self addSubview:label];
    
    return label;
}

@end
