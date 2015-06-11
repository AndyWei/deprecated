//
//  JYFixedLengthRowValidator.m
//  joyyios
//
//  Created by Ping Yang on 6/10/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYFixedLengthRowValidator.h"
#import "XLFormValidatorProtocol.h"
#import "XLFormValidationStatus.h"

@interface JYFixedLengthRowValidator ()

@property NSString *msg;
@property NSUInteger fixedLength;

@end


@implementation JYFixedLengthRowValidator

+ (JYFixedLengthRowValidator *)formFixedLengthValidatorWithMsg:(NSString *)msg length:(NSUInteger)length
{
    return [[JYFixedLengthRowValidator alloc] initWithMsg:msg andFixedLength:length];
}

- (instancetype)initWithMsg:(NSString*)msg andFixedLength:(NSUInteger)length
{
    self = [super init];
    if (self) {
        self.msg = msg;
        self.fixedLength = length;
    }

    return self;
}

- (XLFormValidationStatus *)isValid: (XLFormRowDescriptor *)row
{
    if (row == nil || row.value == nil)
    {
        return nil;
    }

    id value = row.value;
    if ([value isKindOfClass:[NSNumber class]])
    {
        value = [value stringValue];
    }

    if ([value isKindOfClass:[NSString class]])
    {
        BOOL isValid = ([value length] == self.fixedLength);
        return [XLFormValidationStatus formValidationStatusWithMsg:self.msg status:isValid rowDescriptor:row];
    }

    return nil;
};


@end
