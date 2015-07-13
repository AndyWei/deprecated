//
//  JYInvite.m
//  joyyios
//
//  Created by Ping Yang on 4/9/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYDataStore.h"
#import "NSMutableDictionary+Joyy.h"
#import "JYBid.h"
#import "JYInvite.h"
#import "JYUser.h"

static JYInvite *_currentInvite;

@implementation JYInvite

+ (JYInvite *)currentInvite
{
    if (!_currentInvite)
    {
        _currentInvite = [JYDataStore sharedInstance].currentInvite;

        if (!_currentInvite)
        {
            _currentInvite = [[JYInvite alloc] init];
        }
    }

    return _currentInvite;
}

+ (NSNumberFormatter *)sharedPriceFormatter
{
    static NSNumberFormatter *_sharedPriceFormatter = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedPriceFormatter = [[NSNumberFormatter alloc] init];
        _sharedPriceFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    });

    return _sharedPriceFormatter;
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
    _country       = @"us";
    _currency      = @"usd";
    _price         = 0;
    _startTime     = 0;
    _title         = nil;

    _lat = 0.0f;
    _lon = 0.0f;
    _address  = nil;

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
    _status   = (JYInviteStatus)[[dict objectForKey:@"status"] unsignedIntegerValue];
    _title    = [dict objectForKey:@"title"];
    _note     = [dict objectForKey:@"note"];
    _category = [[dict objectForKey:@"category"] unsignedIntegerValue];

    // start time and point
    _startTime = [[dict objectForKey:@"start_time"] unsignedIntegerValue];
    _address  = [dict objectForKey:@"address"];
    _city  = [dict objectForKey:@"city"];
    _lat = [[dict objectForKey:@"lat"] doubleValue];
    _lon = [[dict objectForKey:@"lon"] doubleValue];

    // created date and updated date
    NSString *createdAtString = [dict objectForKey:@"created_at"];
    NSString *updatedAtString = [dict objectForKey:@"updated_at"];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    _createdAt = [dateFormatter dateFromString:createdAtString];
    _updatedAt = [dateFormatter dateFromString:updatedAtString];

    // optional values
    NSString *str = nil;

    str = [dict objectForKey:@"winner_id"];
    _winnerId = [str isKindOfClass:[NSString class]] ? [str unsignedIntegerValue] : 0.0;

    str = [dict objectForKey:@"winner_name"];
    _winnerName = [str isKindOfClass:[NSString class]] ? str : nil;

    str = [dict objectForKey:@"final_price"];
    _finalPrice = [str isKindOfClass:[NSString class]] ? [str unsignedIntegerValue] : 0.0;

    str = [dict objectForKey:@"finished_at"];
    _finishedAt = [str isKindOfClass:[NSString class]] ? [dateFormatter dateFromString:str] : nil;
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

    [parameters setObject:self.address forKey:@"address"];
    [parameters setObject:self.city forKey:@"city"];
    [parameters setObject:@(self.lat) forKey:@"lat"];
    [parameters setObject:@(self.lon) forKey:@"lon"];

    return parameters;
}

- (NSString *)categoryName
{
    NSString *name = nil;
    switch (self.category)
    {
        case JYServiceCategoryAssistant:
            name = NSLocalizedString(@"ASSISTANT", nil);
            break;
        case JYServiceCategoryEscort:
            name = NSLocalizedString(@"ESCORT", nil);
            break;
        case JYServiceCategoryMassage:
            name = NSLocalizedString(@"MASSAGE", nil);
            break;
        case JYServiceCategoryPerformer:
            name = NSLocalizedString(@"PERFORMER", nil);
            break;
        default:
            name = NSLocalizedString(@"OTHER", nil);
            break;
    }
    return name;
}

- (NSString *)moneyString:(NSUInteger)amount
{
    NSNumberFormatter *formatter = [[self class] sharedPriceFormatter];

    NSNumber *centsNumber = [NSNumber numberWithUnsignedInteger:amount];
    NSDecimalNumber *cents = [NSDecimalNumber decimalNumberWithDecimal:[centsNumber decimalValue]];
    NSDecimalNumber *divisor = [[NSDecimalNumber alloc] initWithInt:100];
    NSDecimalNumber *dollars = [cents decimalNumberByDividingBy:divisor];

    return [formatter stringFromNumber:dollars];
}

- (NSString *)priceString
{
    return [self moneyString:self.price];
}

- (NSString *)finalPriceString
{
    return [self moneyString:self.finalPrice];
}

- (NSString *)createTimeString
{
    NSDate *now = [NSDate date];
    NSTimeInterval seconds = [now timeIntervalSinceDate:self.createdAt];

    return [NSString stringFromTimeInterval:seconds];
}

- (NSString *)finishTimeString
{
    if (!self.finishedAt)
    {
        return @"";
    }

    NSDate *now = [NSDate date];
    NSTimeInterval seconds = [now timeIntervalSinceDate:self.finishedAt];

    return [NSString stringFromTimeInterval:seconds];
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

- (UIColor *)paymentStatusColor
{
    UIColor *color = JoyyWhite;
    switch (self.status)
    {
        case JYInviteStatusDealt:
            color = FlatSand;
            break;
        case JYInviteStatusStarted:
            color = FlatSandDark;
            break;
        case JYInviteStatusFinished:
            color = FlatLime;
            break;
        case JYInviteStatusPaid:
            color = FlatLimeDark;
            break;
        default:
            break;
    }

    return color;
}

- (UIColor *)workingStatusColor
{
    UIColor *color = JoyyWhite;
    switch (self.status)
    {
        case JYInviteStatusStarted:
            color = FlatSand;
            break;
        case JYInviteStatusFinished:
            color = FlatLime;
            break;
        case JYInviteStatusPaid:
            color = FlatLimeDark;
            break;
        default:
            break;
    }

    return color;
}

@end
