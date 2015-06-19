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
@property(nonatomic) NSString *stripeCustomerId;
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
    _expiryMonth   = [[dict objectForKey:@"expiry_month"] unsignedIntegerValue];
    _expiryYear    = [[dict objectForKey:@"expiry_year"] unsignedIntegerValue];
}

- (NSString *)cardNumberString
{
    return [NSString stringWithFormat:@"Ending in %@", self.last4];
}

- (NSString *)expireString
{
    return [NSString stringWithFormat:@"%tu/%tu", self.expiryMonth, self.expiryYear];
}
@end
