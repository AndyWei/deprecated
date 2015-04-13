//
//  JYOrder.m
//  joyyios
//
//  Created by Ping Yang on 4/9/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "DataStore.h"
#import "NSMutableDictionary+Joyy.h"
#import "JYOrder.h"
#import "JYServiceCategory.h"
#import "JYUser.h"

static JYOrder *_currentOrder;

@implementation JYOrder

+ (JYOrder *)currentOrder
{
    if (!_currentOrder)
    {
        _currentOrder = [DataStore sharedInstance].currentOrder;

        if (!_currentOrder)
        {
            _currentOrder = [[JYOrder alloc] init];
        }
    }

    return _currentOrder;
}

- (void)clear
{
    _category      = 0;
    _categoryIndex = 0;
    _country       = @"us";
    _currency      = @"usd";
    _price         = 0.0f;
    _startTime     = 0;
    _status        = 0;
    _title         = nil;

    _startPointLat = 0.0f;
    _startPointLon = 0.0f;
    _startAddress  = nil;

    _endPointLat = 0.0f;
    _endPointLon = 0.0f;
    _endAddress  = nil;

    // DO NOT CLEAR _note, we want to keep it to reduce user inputs
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self clear];
    }
    return self;
}

- (NSDictionary *)httpParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithPropertiesOfObject:self];

    [parameters removeObjectForKey:@"categoryIndex"];

    if (self.categoryIndex != JYServiceCategoryIndexDelivery && self.categoryIndex != JYServiceCategoryIndexMoving)
    {
        [parameters removeObjectForKey:@"endPointLat"];
        [parameters removeObjectForKey:@"endPointLon"];
        [parameters removeObjectForKey:@"endPointAddress"];
    }

    return parameters;
}

@end
