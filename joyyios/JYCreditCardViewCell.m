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
static const CGFloat kCardNumberLabelWidth = 120;
static const CGFloat kCheckMarkImageWidth = 20;
static const CGFloat kExpiryLabelWidth = 120;
static const CGFloat kFontSize = 18.0f;

@interface JYCreditCardViewCell ()

@property(nonatomic, weak) UIImageView *cardLogoImageView;
@property(nonatomic, weak) UIImageView *checkMarkImageView;
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

        [self _createCardImageView];
        [self _createCheckMarkImageView];
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

    self.checkMarkImageView.image = [card isDefault] ? [UIImage imageNamed:@"checkMark"] : nil;
}

- (void)_createCardImageView
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(kMarginLeft, 3, kCardImageWidth, kCardImageWidth)];
    [self addSubview:imageView];
    self.cardLogoImageView = imageView;
}

- (void)_createCheckMarkImageView
{
    CGFloat x = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - kMarginRight - kCheckMarkImageWidth;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, 13, kCheckMarkImageWidth, kCheckMarkImageWidth)];
    [self addSubview:imageView];
    self.checkMarkImageView = imageView;
}

- (void)_createCardNumberLabel
{
    self.cardNumberLabel = [self _createLabel];
    CGFloat x = CGRectGetMaxX(self.cardLogoImageView.frame) + kMarginLeft;
    self.cardNumberLabel.frame = CGRectMake(x, 0, kCardNumberLabelWidth, kLabelHeight);
}

- (void)_createExpiryLabel
{
    CGFloat x = CGRectGetMaxX(self.cardNumberLabel.frame);

    self.expiryLabel = [self _createLabel];
    self.expiryLabel.frame = CGRectMake(x, 0, kExpiryLabelWidth, kLabelHeight);
    self.expiryLabel.textAlignment = NSTextAlignmentLeft;
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

