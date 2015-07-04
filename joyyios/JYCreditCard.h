//
//  JYCreditCard.h
//  joyyios
//
//  Created by Ping Yang on 6/18/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

typedef NS_ENUM(NSInteger, JYCreditCardType)
{
    JYCreditCardTypeUnrecognized = 0, // The card number does not correspond to any recognizable card type.
    JYCreditCardTypeAmbiguous = 1,    // The card number corresponds to multiple card types
    JYCreditCardTypeAmex = '3',       // American Express
    JYCreditCardTypeVisa = '4',       // VISA
    JYCreditCardTypeMastercard = '5', // MasterCard
    JYCreditCardTypeDiscover = '6',   // Discover Card
    JYCreditCardTypeApplePay = 'A',   // Apple Pay
    JYCreditCardTypeJCB = 'J',        // Japan Credit Bureau
    JYCreditCardTypeAdd = 'N'         // Dummy credit card type for add button
};

@interface JYCreditCard : NSObject

+ (instancetype)applePayCard;
+ (instancetype)dummyCard;
+ (instancetype)cardWithType:(JYCreditCardType)type fromSTPCard:(STPCard *)stpCard;
- (instancetype)init;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (BOOL)isDefault;
- (void)setAsDefault;

@property(nonatomic) NSString *stripeCustomerId;
@property(nonatomic, readonly) NSString *cardNumberString;
@property(nonatomic, readonly) NSString *typeString;
@property(nonatomic, readonly) NSString *expiryString;
@property(nonatomic, readonly) UIImage  *logoImage;


@end
