//
//  JYCreditCard.m
//  joyyios
//
//  Created by Ping Yang on 6/18/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "DataStore.h"
#import "JYCreditCard.h"

@interface JYCreditCard ()

@property(nonatomic) JYCreditCardType cardType;
@property(nonatomic) NSUInteger expiryMonth;
@property(nonatomic) NSUInteger expiryYear;
@property(nonatomic, copy) NSString *last4;

@end


@implementation JYCreditCard

+ (instancetype)applePayCard
{
    JYCreditCard *card = [JYCreditCard new];
    card.cardType = JYCreditCardTypeApplePay;
    card.stripeCustomerId = @"applePay";
    card.last4 = @"0000";
    return card;
}

+ (instancetype)dummyCard
{
    JYCreditCard *card = [JYCreditCard new];
    card.cardType = JYCreditCardTypeAdd;
    return card;
}

+ (instancetype)cardWithType:(JYCreditCardType)type fromSTPCard:(STPCard *)stpCard
{
    JYCreditCard *card = [JYCreditCard new];
    card.cardType = type;
    card.last4 = stpCard.last4;
    card.expiryMonth = stpCard.expMonth;
    card.expiryYear = stpCard.expYear;

    return card;
}

- (instancetype)init
{
    self = [super init];

    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        [self loadFromDictionary:dict];
    }
    return self;
}

- (void)loadFromDictionary:(NSDictionary *)dict
{
    if (!dict)
    {
        return;
    }

    _last4  = [dict objectForKey:@"number_last_4"];
    _stripeCustomerId = [dict objectForKey:@"stripe_customer_id"];
    _cardType = [[dict objectForKey:@"card_type"] unsignedIntegerValue];
    _expiryMonth   = [[dict objectForKey:@"expiry_month"] unsignedIntegerValue];
    _expiryYear    = [[dict objectForKey:@"expiry_year"] unsignedIntegerValue];
}

- (BOOL)isDefault
{
    NSString *defaultCustomerId = [DataStore sharedInstance].defaultCustomerId;
    NSString *defaultCardNumber = [DataStore sharedInstance].defaultCardNumber;

    return [self.stripeCustomerId isEqualToString:defaultCustomerId] && [self.last4 isEqualToString:defaultCardNumber];
}

- (void)setAsDefault
{
    [DataStore sharedInstance].defaultCardNumber = self.last4;
    [DataStore sharedInstance].defaultCustomerId = self.stripeCustomerId;
}

- (NSString *)cardNumberString
{
    if (self.cardType == JYCreditCardTypeAdd)
    {
        return NSLocalizedString(@"ADD CREDIT CARD", nil);
    }
    else if (self.cardType == JYCreditCardTypeApplePay)
    {
        return NSLocalizedString(@"APPLE PAY", nil);
    }

    NSString *prefix = NSLocalizedString(@"ENDING IN", nil);
    return [NSString stringWithFormat:@"%@ %@", prefix, self.last4];
}

- (NSString *)expiryString
{
    if (self.cardType == JYCreditCardTypeAdd || self.cardType == JYCreditCardTypeApplePay)
    {
        return @"";
    }

    return [NSString stringWithFormat:@"expiry: %02tu/%tu", self.expiryMonth, self.expiryYear];
}

- (NSString *)typeString
{
    NSString *str = nil;
    switch (self.cardType)
    {
        case JYCreditCardTypeAmex:
            str = @"amex";
            break;
        case JYCreditCardTypeDiscover:
            str = @"discover";
            break;
        case JYCreditCardTypeJCB:
            str = @"jcb";
            break;
        case JYCreditCardTypeMastercard:
            str = @"masterCard";
            break;
        case JYCreditCardTypeVisa:
            str = @"visa";
            break;
        case JYCreditCardTypeAdd:
            str = @"addCard";
            break;
        case JYCreditCardTypeApplePay:
            str = @"applePay";
            break;
        default:
            break;
    }
    return str;
}

- (UIImage *)logoImage
{
    return (self.typeString == nil)? nil : [UIImage imageNamed:self.typeString];
}

@end
