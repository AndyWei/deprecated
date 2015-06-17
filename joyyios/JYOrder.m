//
//  JYOrder.m
//  joyyios
//
//  Created by Ping Yang on 4/9/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "DataStore.h"
#import "NSMutableDictionary+Joyy.h"
#import "JYBid.h"
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

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self clear];
        _bids = [NSMutableArray new];
        _comments = [NSMutableArray new];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        [self loadFromDictionary:dict];
        _bids = [NSMutableArray new];
        _comments = [NSMutableArray new];
    }
    return self;
}

- (void)clear
{
    _category      = 0;
    _categoryIndex = 0;
    _country       = @"us";
    _currency      = @"usd";
    _price         = 0.0f;
    _startTime     = 0;
    _title         = nil;

    _startPointLat = 0.0f;
    _startPointLon = 0.0f;
    _startAddress  = nil;

    _endPointLat = 0.0f;
    _endPointLon = 0.0f;
    _endAddress  = nil;

    // DO NOT CLEAR _note, we want to keep it to reduce user inputs
}

- (void)loadFromDictionary:(NSDictionary *)dict
{
    if (!dict)
    {
        [self clear];
        return;
    }

    _orderId  = [[dict objectForKey:@"id"] unsignedIntegerValue];
    _userId   = [[dict objectForKey:@"user_id"] unsignedIntegerValue];
    _price    = [[dict objectForKey:@"price"] unsignedIntegerValue];
    _country  = [dict objectForKey:@"country"];
    _currency = [dict objectForKey:@"currency"];
    _status   = (JYOrderStatus)[[dict objectForKey:@"status"] unsignedIntegerValue];
    _title    = [dict objectForKey:@"title"];
    _note     = [dict objectForKey:@"note"];
    _category = [[dict objectForKey:@"category"] unsignedIntegerValue];
    _categoryIndex = [JYServiceCategory indexOfCategory:_category];

    // start time and point
    _startTime = [[dict objectForKey:@"start_time"] unsignedIntegerValue];
    _startAddress  = [dict objectForKey:@"start_address"];
    _startPointLat = [[dict objectForKey:@"start_point_lat"] doubleValue];
    _startPointLon = [[dict objectForKey:@"start_point_lon"] doubleValue];

    // created date and updated date
    NSString *createdAtString = [dict objectForKey:@"created_at"];
    NSString *updatedAtString = [dict objectForKey:@"created_at"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    _createdAt = [dateFormatter dateFromString:createdAtString];
    _updatedAt = [dateFormatter dateFromString:updatedAtString];

    // optional values
    NSString *str = nil;
    if (self.hasEndAddress)
    {
        _endAddress  = [dict objectForKey:@"end_address"];


        str = [dict objectForKey:@"end_point_lat"];
        _endPointLat = [str isKindOfClass:[NSString class]] ? [str doubleValue] : 0.0;

        str = [dict objectForKey:@"end_point_lon"];
        _endPointLon = [str isKindOfClass:[NSString class]] ? [str doubleValue] : 0.0;
    }

    str = [dict objectForKey:@"winner_id"];
    _winnnerId = [str isKindOfClass:[NSString class]] ? [str unsignedIntegerValue] : 0.0;

    str = [dict objectForKey:@"final_price"];
    _finalPrice = [str isKindOfClass:[NSString class]] ? [str unsignedIntegerValue] : 0.0;
}

- (NSDictionary *)httpParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:@(self.category) forKey:@"category"];
    [parameters setObject:@(self.price) forKey:@"price"];
    [parameters setObject:@(self.startTime) forKey:@"start_time"];
    [parameters setObject:self.currency forKey:@"currency"];
    [parameters setObject:self.country forKey:@"country"];
    [parameters setObject:self.title forKey:@"title"];
    [parameters setObject:self.note forKey:@"note"];

    [parameters setObject:self.startAddress forKey:@"start_address"];
    [parameters setObject:self.startCity forKey:@"start_city"];
    [parameters setObject:@(self.startPointLat) forKey:@"start_point_lat"];
    [parameters setObject:@(self.startPointLon) forKey:@"start_point_lon"];


    if (self.hasEndAddress)
    {
        [parameters setObject:self.endAddress forKey:@"end_address"];
        [parameters setObject:@(self.endPointLat) forKey:@"end_point_lat"];
        [parameters setObject:@(self.endPointLon) forKey:@"end_point_lon"];
    }

    return parameters;
}

- (BOOL)hasEndAddress
{
    BOOL result = self.categoryIndex == JYServiceCategoryIndexDelivery ||
                  self.categoryIndex == JYServiceCategoryIndexMoving;
    return result;
}

- (NSString *)priceString
{
    return [NSString stringWithFormat:@"$%tu", self.price];
}

- (NSString *)finalPriceString
{
    return [NSString stringWithFormat:@"$%tu", self.finalPrice];
}

- (NSString *)createTimeString
{
    NSDate *now = [NSDate date];
    NSTimeInterval secondsBetween = [now timeIntervalSinceDate:self.createdAt];

    NSString *ago = NSLocalizedString(@"ago", nil);
    int numberOfDays = secondsBetween / 86400;
    if (numberOfDays > 0)
    {
        NSString *days = NSLocalizedString(@"d", nil);

        return [NSString stringWithFormat:@"%d %@ %@", numberOfDays, days, ago];
    }

    int numberOfHours = secondsBetween / 3600;
    if (numberOfHours > 0)
    {
        NSString *hours = NSLocalizedString(@"h", nil);

        return [NSString stringWithFormat:@"%d %@ %@", numberOfHours, hours, ago];
    }

    int numberOfMinutes = secondsBetween / 60;
    if (numberOfMinutes > 0)
    {
        NSString *minutes = NSLocalizedString(@"m", nil);

        return [NSString stringWithFormat:@"%d %@ %@", numberOfMinutes, minutes, ago];
    }

    int numberOfSeconds = (int)secondsBetween;
    NSString *seconds = NSLocalizedString(@"s", nil);
    return [NSString stringWithFormat:@"%d %@ %@", numberOfSeconds, seconds, ago];
}

- (UIColor *)bidColor
{
    UIColor *color = JoyyWhite;
    if (self.bids.count > 0)
    {
        JYBid *bid = [self.bids lastObject];
        color = bid.expired ? FlatYellow : FlatLime;
    }
    return color;
}

- (UIColor *)statusColor
{
    UIColor *color = JoyyWhite;
    switch (self.status)
    {
        case JYOrderStatusOngoing:
            color = FlatSand;
            break;
        case JYOrderStatusFinished:
            color = FlatLime;
            break;
        case JYOrderStatusPaid:
            color = FlatLimeDark;
            break;
        default:
            break;
    }

    return color;
}

@end
