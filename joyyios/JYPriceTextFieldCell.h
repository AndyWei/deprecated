//
//  JYPriceTextFieldCell.h
//  joyyios
//
//  Created by Ping Yang on 4/11/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "XLFormBaseCell.h"

extern NSString *const XLFormRowDescriptorTypePrice;

@interface JYPriceTextFieldCell : XLFormBaseCell

@property (nonatomic, readonly) UILabel * textLabel;
@property (nonatomic, readonly) UITextField * textField;

@end
