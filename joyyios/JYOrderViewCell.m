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
static const CGFloat kButtonHeight = 30.0f;

@interface JYOrderViewCell ()

@property(nonatomic, weak) JYOrderCard *card;
@property(nonatomic, weak) UILabel *label1;
@property(nonatomic, weak) UILabel *label2;
@property(nonatomic, weak) JYButton *payButton;

@end


@implementation JYOrderViewCell

+ (CGFloat)cellHeightForOrder:(JYOrder *)order
{
    CGFloat cardHeight = [JYOrderCard cardHeightForOrder:order withAddress:NO andBid:NO];
    CGFloat labelHeight = (order.status == JYOrderStatusFinished) ? kLabelHeight * 2 : kLabelHeight;
    CGFloat buttonHeight = (order.status == JYOrderStatusFinished) ? kButtonHeight : 0;
    return  cardHeight + labelHeight + buttonHeight;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        [self _createOrderCard];
        self.label1 = [self _createLabel];
        self.label2 = [self _createLabel];
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
    CGRect frame = CGRectMake(0, 0, width, 0);
    JYButton *button = [[JYButton alloc] initWithFrame:frame buttonStyle:JYButtonStyleDefault];

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
    self.card.height = [JYOrderCard cardHeightForOrder:self.order withAddress:NO andBid:NO];

    if (order.status == JYOrderStatusFinished)
    {
        NSString *chose = NSLocalizedString(@"You chose", nil);
        NSString *atPrice = NSLocalizedString(@"at the price", nil);
        self.label1.text = [NSString stringWithFormat:@"%@ @%@ %@ %@", chose, order.winnerName, atPrice, order.finalPriceString];

        NSString *fnished = NSLocalizedString(@"finished the service", nil);
        self.label2.text = [NSString stringWithFormat:@"@%@ %@ %@ ", order.winnerName, fnished, order.finishTimeString];

        self.payButton.textLabel.text = NSLocalizedString(@"Pay", nil);
    }
    else
    {
        NSString *paid = NSLocalizedString(@"You paid", nil);
        self.label1.text = [NSString stringWithFormat:@"%@ @%@ %@", paid, order.winnerName, order.finalPriceString];
        self.label2.text = nil;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self.card layoutSubviews];
    self.label1.y = CGRectGetMaxY(self.card.frame);

    if (self.order.status == JYOrderStatusFinished)
    {
        // show label2
        self.label2.y = CGRectGetMaxY(self.label1.frame);
        self.label2.height = kLabelHeight;

        // show paybutton
        self.payButton.y = CGRectGetMaxY(self.label2.frame);
        self.payButton.height = kButtonHeight;
    }
    else
    {
        // hide label2
        self.label2.height = 0;

        // hide paybutton
        self.payButton.height = 0;
    }
}

@end
