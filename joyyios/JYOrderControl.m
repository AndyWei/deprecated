//
//  JYOrderControl.m
//  joyyios
//
//  Created by Ping Yang on 6/29/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYButton.h"
#import "JYOrderControl.h"
#import "JYOrderCard.h"

static const CGFloat kLabelHeight = 30.0f;
static const CGFloat kButtonHeight = 30.0f;

@interface JYOrderControl ()

@property(nonatomic, weak) JYOrderCard *card;
@property(nonatomic, weak) UILabel *label1;
@property(nonatomic, weak) UILabel *label2;
@property(nonatomic, weak) JYButton *payButton;

@end

@implementation JYOrderControl

+ (CGFloat)heightForOrder:(JYOrder *)order
{
    CGFloat cardHeight = [JYOrderCard heightForOrder:order withAddress:NO andBid:NO];
    CGFloat labelHeight = 0;
    CGFloat buttonHeight = 0;

    switch (order.status)
    {
        case JYOrderStatusDealt:
            labelHeight = kLabelHeight;
            buttonHeight = 0;
            break;
        case JYOrderStatusStarted:
            labelHeight = kLabelHeight * 2;
            buttonHeight = 0;
            break;
        case JYOrderStatusFinished:
            labelHeight = kLabelHeight * 2;
            buttonHeight = kButtonHeight;
            break;
        case JYOrderStatusPaid:
            labelHeight = kLabelHeight;
            buttonHeight = 0;
            break;
        default:
            break;
    }

    return  cardHeight + labelHeight + buttonHeight;
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
    [self _createOrderCard];
    self.label1 = [self _createLabel];
    self.label2 = [self _createLabel];
    [self _createPayButton];
}

- (void)_createOrderCard
{
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]);

    JYOrderCard *card = [[JYOrderCard alloc] initWithFrame:CGRectMake(0, 0, width, 100)];
    card.userInteractionEnabled = NO;

    self.card = card;
    _color = self.backgroundColor = self.card.backgroundColor = JoyyWhite;

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

- (void)setColor:(UIColor *)color
{
    if (_color == color)
    {
        return;
    }
    _color = color;
    self.backgroundColor = self.card.backgroundColor = color;
}

- (void)setOrder:(JYOrder *)order
{
    _order = order;
    [self.card presentOrder:order withAddress:NO andBid:NO];
    self.card.height = [JYOrderCard heightForOrder:self.order withAddress:NO andBid:NO];

    self.label1.text = nil;
    self.label2.text = nil;
    self.payButton.textLabel.text = nil;
    switch (order.status)
    {
        case JYOrderStatusDealt:
            self.label1.text = [self _choseString];
            break;
        case JYOrderStatusStarted:
            self.label1.text = [self _choseString];
            self.label2.text = [self _startedString];
            break;
        case JYOrderStatusFinished:
            self.label1.text = [self _choseString];
            self.label2.text = [self _finishedString];
            self.payButton.textLabel.text = NSLocalizedString(@"Pay", nil);
            break;
        case JYOrderStatusPaid:
            self.label1.text = [self _paidString];
            break;
        default:
            break;
    }
}

- (NSString *)_choseString
{
    NSString *chose = NSLocalizedString(@"You chose", nil);
    NSString *atPrice = NSLocalizedString(@"at the price", nil);
    return[NSString stringWithFormat:@"%@ @%@ %@ %@", chose, self.order.winnerName, atPrice, self.order.finalPriceString];
}

- (NSString *)_startedString
{
    NSString *fnished = NSLocalizedString(@"started the service", nil);
    return [NSString stringWithFormat:@"@%@ %@", self.order.winnerName, fnished];
}

- (NSString *)_finishedString
{
    NSString *fnished = NSLocalizedString(@"finished the service", nil);
    return [NSString stringWithFormat:@"@%@ %@ %@ ", self.order.winnerName, fnished, self.order.finishTimeString];
}

- (NSString *)_paidString
{
    NSString *paid = NSLocalizedString(@"You paid", nil);
    return [NSString stringWithFormat:@"%@ @%@ %@", paid, self.order.winnerName, self.order.finalPriceString];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self.card layoutSubviews];

    self.label1.y = CGRectGetMaxY(self.card.frame);
    self.label1.height = 0;
    self.label2.height = 0;
    self.payButton.height = 0;

    switch (self.order.status)
    {
        case JYOrderStatusDealt:
            self.label1.height = kLabelHeight;
            break;
        case JYOrderStatusStarted:
            self.label1.height = kLabelHeight;
            self.label2.y = CGRectGetMaxY(self.label1.frame);
            self.label2.height = kLabelHeight;
            break;
        case JYOrderStatusFinished:
            self.label1.height = kLabelHeight;
            self.label2.y = CGRectGetMaxY(self.label1.frame);
            self.label2.height = kLabelHeight;
            self.payButton.y = CGRectGetMaxY(self.label2.frame);
            self.payButton.height = kButtonHeight;
            break;
        default:
            break;
    }
}

@end
