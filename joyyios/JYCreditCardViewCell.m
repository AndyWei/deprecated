//
//  JYCreditCardViewCell.m
//  joyyios
//
//  Created by Ping Yang on 6/18/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYCreditCardViewCell.h"

static const CGFloat kLabelHeight = 55;
static const CGFloat kLabelWidth = 100;
static const CGFloat kLeftMargin = 8.0f;
static const CGFloat kFontSize = 18.0f;

@interface JYCreditCardViewCell ()

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

        [self _createCardNumberLabel];
        [self _createExpiryLabel];
    }
    return self;
}

- (void)presentCreditCard:(JYCreditCard *)card
{
    self.cardNumberLabel.text = card.cardNumberString;
    self.expiryLabel.text = card.expiryString;
}

- (void)_createCardNumberLabel
{
    self.cardNumberLabel = [self _createLabel];
}

- (void)_createExpiryLabel
{
    self.expiryLabel = [self _createLabel];
    self.expiryLabel.x = CGRectGetMaxX(self.cardNumberLabel.frame);
    self.expiryLabel.textAlignment = NSTextAlignmentRight;
}

- (UILabel *)_createLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kLeftMargin, 0, kLabelWidth, kLabelHeight)];
    label.backgroundColor = ClearColor;
    label.font = [UIFont systemFontOfSize:kFontSize];
    label.textColor = FlatBlack;
    label.textAlignment = NSTextAlignmentLeft;
    [self addSubview:label];

    return label;
}
@end

