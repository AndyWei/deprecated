//
//  JYPerson.m
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYPerson.h"

@interface JYPerson ()
@property (nonatomic) NSUInteger yearOfBirth;
@end

@implementation JYPerson

#pragma mark - Object Lifecycle

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        _bio  = [dict objectForKey:@"bio"];
        _name = [dict objectForKey:@"name"];
        _org  = [dict objectForKey:@"org"];
        _photoFilename = [dict objectForKey:@"ppf"];
        _friendCount = [dict unsignedIntegerValueForKey:@"friends"];
        _gender      = [dict unsignedIntegerValueForKey:@"gender"];
        _heartCount  = [dict unsignedIntegerValueForKey:@"hearts"];
        _orgType     = [dict unsignedIntegerValueForKey:@"orgtype"];
        _personId    = [dict unsignedIntegerValueForKey:@"id"];
        _score       = [dict unsignedIntegerValueForKey:@"score"];
        _yearOfBirth = [dict unsignedIntegerValueForKey:@"yob"];
        _membershipExpiryTimestamp = [dict unsignedIntegerValueForKey:@"met"];
    }
    return self;
}

- (NSString *)age
{
    if (self.yearOfBirth == 0)
    {
        return nil;
    }

    if (!_age)
    {
        NSCalendar *gregorian = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        NSInteger year = [gregorian component:NSCalendarUnitYear fromDate:NSDate.date];
        NSInteger age = year - self.yearOfBirth;
        _age = [NSString stringWithFormat:@"%ld", (long)age];
    }
    return _age;
}

- (NSString *)idString
{
    return [NSString stringWithFormat:@"%tu", self.personId];
}

- (NSString *)url
{
    return [NSString stringWithFormat:@"%@%@.jpg", [self baseURL], self.photoFilename];
}

- (NSString *)baseURL
{
    NSString *url = @"https://joyydev.s3.amazonaws.com/";
//    switch (self.urlVersion)
//    {
//        case 0:
//            break;
//        case 1:
//            // url = ....
//            break;
//        default:
//            break;
//    }
    return url;
}

@end
