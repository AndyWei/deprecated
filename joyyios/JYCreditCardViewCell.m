//
//  JYCreditCardViewCell.m
//  joyyios
//
//  Created by Ping Yang on 6/18/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYCreditCardViewCell.h"

static const CGFloat kLabelHeight = 55;
static const CGFloat kCardImageWidth = 48;
static const CGFloat kCardNumberLabelWidth = 150;
static const CGFloat kLeftMargin = 8.0f;
static const CGFloat kRigthMargin = 8.0f;
static const CGFloat kFontSize = 18.0f;

@interface JYCreditCardViewCell ()

@property(nonatomic, weak) UIImageView *cardLogoImageView;
@property(nonatomic, weak) UILabel *cardNumberLabel;
@property(nonatomic, weak) UILabel *expiryLabel;

@end


@implementation JYCreditCardViewCell


+ (CGFloat)cellHeight
{
    return kLabelHeight;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = JoyyWhite;

        [self _createCardImage];
        [self _createCardNumberLabel];
        [self _createExpiryLabel];
    }
    return self;
}

- (void)presentCreditCard:(JYCreditCard *)card
{
    self.cardNumberLabel.text = card.cardNumberString;
    self.expiryLabel.text = card.expiryString;

    self.cardLogoImageView.image = card.logoImage;
}

- (void)_createCardImage
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(kLeftMargin, 3, kCardImageWidth, kCardImageWidth)];
    [self addSubview:imageView];
    self.cardLogoImageView = imageView;
}

- (void)_createCardNumberLabel
{
    self.cardNumberLabel = [self _createLabel];
    CGFloat x = CGRectGetMaxX(self.cardLogoImageView.frame) + kLeftMargin;
    self.cardNumberLabel.frame = CGRectMake(x, 0, kCardNumberLabelWidth, kLabelHeight);
}

- (void)_createExpiryLabel
{
    CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]);
    CGFloat x = CGRectGetMaxX(self.cardNumberLabel.frame);
    CGFloat width = screenWidth - x - kRigthMargin;

    self.expiryLabel = [self _createLabel];
    self.expiryLabel.frame = CGRectMake(x, 0, width, kLabelHeight);
    self.expiryLabel.textAlignment = NSTextAlignmentRight;
}

- (UILabel *)_createLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.backgroundColor = ClearColor;
    label.font = [UIFont systemFontOfSize:kFontSize];
    label.textColor = FlatBlack;
    label.textAlignment = NSTextAlignmentLeft;
    [self addSubview:label];

    return label;
}
@end

