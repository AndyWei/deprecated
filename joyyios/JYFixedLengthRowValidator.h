//
//  JYFixedLengthRowValidator.h
//  joyyios
//
//  Created by Ping Yang on 6/10/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "XLFormValidator.h"

@interface JYFixedLengthRowValidator : XLFormValidator

- (instancetype)initWithMsg:(NSString*)msg andFixedLength:(NSUInteger)length;
+ (JYFixedLengthRowValidator *)formFixedLengthValidatorWithMsg:(NSString *)msg length:(NSUInteger)length;

@end