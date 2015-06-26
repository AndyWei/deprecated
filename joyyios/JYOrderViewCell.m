//
//  JYOrderViewCell.m
//  joyyios
//
//  Created by Ping Yang on 6/21/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYButton.h"
#import "JYOrderCard.h"
#import "JYOrderViewCell.h"

static const CGFloat kLabelHeight = 30.0f;

@interface JYOrderViewCell ()

@property(nonatomic, weak) JYOrderCard *card;
@property(nonatomic, weak) UILabel *bidLabel;
@property(nonatomic, weak) UILabel *statusLabel;
@property(nonatomic, weak) JYButton *payButton;

@end


@implementation JYOrderViewCell

+ (CGFloat)cellHeightForOrder:(JYOrder *)order
{
    return [JYOrderCard cardHeightForOrder:order withAddress:NO andBid:NO];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        [self _createOrderCard];
        self.bidLabel = [self _createLabel];
        self.statusLabel = [self _createLabel];
        [self _createPayButton];

    }
    return self;
}

- (void)_createOrderCard
{
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]);

    JYOrderCard *card = [[JYOrderCard alloc] initWithFrame:CGRectMake(0, 0, width, 100)];
    card.userInteractionEnabled = NO;

    self.card = card;
    _cellColor = self.backgroundColor = self.card.backgroundColor = JoyyWhite;

    [self addSubview:self.card];
}

- (UILabel *)_createLabel
{
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame])  - kMarginRight;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, kLabelHeight)];
    label.font = [UIFont systemFontOfSize:kFontSizeBody];
    label.textColor = FlatBlack;
    label.textAlignment = NSTextAlignmentRight;
    label.userInteractionEnabled = NO;

    [self addSubview:label];

    return label;
}

- (void)_createPayButton
{
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]);
    CGRect frame = CGRectMake(0, 0, width, kLabelHeight);
    JYButton *button = [[JYButton alloc] initWithFrame:frame buttonStyle:JYButtonStyleDefault];

    button.textLabel.text = NSLocalizedString(@"Pay", nil);
    button.backgroundColor = ClearColor;
    button.contentColor = JoyyWhite;
    button.foregroundColor = FlatGreen;
    button.textLabel.font = [UIFont boldSystemFontOfSize:18];
    [button addTarget:self action:@selector(_pay) forControlEvents:UIControlEventTouchUpInside];

    self.payButton = button;
    [self addSubview:self.payButton];
}

- (void)_pay
{
}

- (void)setCellColor:(UIColor *)color
{
    if (_cellColor == color)
    {
        return;
    }
    _cellColor = color;
    self.backgroundColor = self.card.backgroundColor = color;
}

- (void)setOrder:(JYOrder *)order
{
    _order = order;
    [self.card presentOrder:order withAddress:NO andBid:NO];
    self.bidLabel.text = @"you accepted xxx's bid at $mmm"; // TODO
    self.statusLabel.text = @"xxx finished your order at";
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat cardHeight = self.height - kLabelHeight * 2;
    cardHeight -= (self.order.status == JYOrderStatusPaid) ? 0 : kLabelHeight;
    self.card.height = cardHeight;
    [self.card layoutSubviews];
}
@end
