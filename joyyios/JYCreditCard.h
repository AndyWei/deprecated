//
//  JYCreditCard.h
//  joyyios
//
//  Created by Ping Yang on 6/18/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

typedef NS_ENUM(NSInteger, JYCreditCardType) {
    /// The card number does not correspond to any recognizable card type.
    JYCreditCardTypeUnrecognized = 0,
    /// The card number corresponds to multiple card types (e.g., when only a few digits have been entered).
    JYCreditCardTypeAmbiguous = 1,
    /// American Express
    JYCreditCardTypeAmex = '3',
    /// Japan Credit Bureau
    JYCreditCardTypeJCB = 'J',
    /// VISA
    JYCreditCardTypeVisa = '4',
    /// MasterCard
    JYCreditCardTypeMastercard = '5',
    /// Discover Card
    JYCreditCardTypeDiscover = '6'
};

@interface JYCreditCard : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@property(nonatomic, readonly) NSString *cardNumberString;
@property(nonatomic, readonly) NSString *expiryString;


@end
