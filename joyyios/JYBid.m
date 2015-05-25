//
//  JYBid.m
//  joyyios
//
//  Created by Ping Yang on 5/24/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYBid.h"

@implementation JYBid

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        if (dict)
        {
            self.bidId = [[dict objectForKey:@"id"] unsignedIntegerValue];
            self.orderId = [[dict objectForKey:@"order_id"] unsignedIntegerValue];
            self.userId = [[dict objectForKey:@"user_id"] unsignedIntegerValue];
            self.price = [[dict objectForKey:@"price"] unsignedIntegerValue];
            self.status = [[dict objectForKey:@"status"] integerValue];
            self.note = [dict objectForKey:@"note"];

            NSUInteger expireTimestamp = [[dict objectForKey:@"expire_at"] unsignedIntegerValue];
            self.expireTime = [NSDate dateWithTimeIntervalSinceReferenceDate:expireTimestamp];

            // Optional properties
            self.username = [dict objectForKey:@"username"];

            NSString *str = nil;
            str = [dict objectForKey:@"rating_total"];
            self.userRatingTotal = [str isKindOfClass:[NSString class]] ? [str unsignedIntegerValue] : 0.0;

            str = [dict objectForKey:@"rating_count"];
            self.userRatingCount = [str isKindOfClass:[NSString class]] ? [str unsignedIntegerValue] : 0.0;
        }
    }
    return self;
}

- (BOOL)expired
{
    NSTimeInterval secondsBetween = [self.expireTime timeIntervalSinceNow];
    return (secondsBetween < 0);
}

- (NSString *)expireTimeString
{
    NSTimeInterval secondsBetween = [self.expireTime timeIntervalSinceNow];

    if (secondsBetween < 0)
    {
        return NSLocalizedString(@"expired", nil);
    }

    NSString *expireString = NSLocalizedString(@"expire in", nil);
    int numberOfDays = secondsBetween / 86400;
    if (numberOfDays > 0)
    {
        NSString *days = (numberOfDays == 1) ? NSLocalizedString(@"day", nil) : NSLocalizedString(@"days", nil);

        return [NSString stringWithFormat:@"%@ %d %@", expireString, numberOfDays, days];
    }

    int numberOfHours = secondsBetween / 3600;
    if (numberOfHours > 0)
    {
        NSString *hours = (numberOfHours == 1) ? NSLocalizedString(@"hour", nil) : NSLocalizedString(@"hours", nil);

        return [NSString stringWithFormat:@"%@ %d %@", expireString, numberOfHours, hours];
    }

    int numberOfMinutes = secondsBetween / 60;
    if (numberOfMinutes > 0)
    {
        NSString *minutes = (numberOfMinutes == 1) ? NSLocalizedString(@"min", nil) : NSLocalizedString(@"mins", nil);

        return [NSString stringWithFormat:@"%@ %d %@", expireString, numberOfMinutes, minutes];
    }

    int numberOfSeconds = (int)secondsBetween;
    NSString *seconds = (numberOfSeconds == 1) ? NSLocalizedString(@"sec", nil) : NSLocalizedString(@"secs", nil);
    return [NSString stringWithFormat:@"%@ %d %@", expireString, numberOfSeconds, seconds];
}

- (NSString *)priceString
{
    return [NSString stringWithFormat:@"$%tu", self.price];
}

@end
