//
//  Order.m
//  joyyios
//
//  Created by Ping Yang on 4/9/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYOrder.h"
#import "JYUser.h"

static JYOrder *_currentOrder;

@implementation JYOrder

+ (JYOrder *)currentOrder
{
    if (!_currentOrder)
    {
        _currentOrder = [[JYOrder alloc] init];
    }

    return _currentOrder;
}

+ (void)deleteCurrentOrder
{
    _currentOrder = nil;
}

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        _orderId   = 0;
        _winnnerId = 0;
        _status    = 0;
        _category  = 0;
        _categoryIndex = 0;
        _amount          = 0.0f;
        _finalAmount     = 0.0f;
        _unitPrice       = 0.0f;
        _finalUnitPrice  = 0.0f;
        _totalPrice      = 0.0f;
        _finalTotalPrice = 0.0f;
        _userId   = [JYUser currentUser].userId;
        _currency = @"usd";
        _country  = @"us";
    }
    return self;
}

- (void)submit
{
}

@end
