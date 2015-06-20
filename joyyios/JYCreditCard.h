//
//  JYCreditCard.h
//  joyyios
//
//  Created by Ping Yang on 6/18/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

typedef NS_ENUM(NSInteger, JYCreditCardType)
{
    JYCreditCardTypeUnrecognized = 0, // The card number does not correspond to any recognizable card type.
    JYCreditCardTypeAmbiguous = 1,    // The card number corresponds to multiple card types
    JYCreditCardTypeAmex = '3',       // American Express
    JYCreditCardTypeJCB = 'J',        // Japan Credit Bureau
    JYCreditCardTypeVisa = '4',       // VISA
    JYCreditCardTypeMastercard = '5', // MasterCard
    JYCreditCardTypeDiscover = '6'    // Discover Card
};

@interface JYCreditCard : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@property(nonatomic) NSString *stripeCustomerId;
@property(nonatomic, readonly) NSString *cardNumberString;
@property(nonatomic, readonly) NSString *typeString;
@property(nonatomic, readonly) NSString *expiryString;


@end
