//
//  JYCreditCardViewCell.h
//  joyyios
//
//  Created by Ping Yang on 6/18/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYCreditCard.h"

@interface JYCreditCardViewCell : UITableViewCell

+ (CGFloat)cellHeight;

- (void)presentCreditCard:(JYCreditCard *)card;

@end