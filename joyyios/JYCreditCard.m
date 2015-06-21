//
//  JYCreditCard.m
//  joyyios
//
//  Created by Ping Yang on 6/18/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYCreditCard.h"

@interface JYCreditCard ()

@property(nonatomic) JYCreditCardType cardType;
@property(nonatomic) NSString *last4;
@property(nonatomic) NSUInteger expiryMonth;
@property(nonatomic) NSUInteger expiryYear;

@end


@implementation JYCreditCard

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

- (NSString *)cardNumberString
{
    return [NSString stringWithFormat:@"ending in %@", self.last4];
}

- (NSString *)expiryString
{
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
