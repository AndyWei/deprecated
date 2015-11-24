//
//  JYPerson.m
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFilename.h"

@interface JYUser ()
@property (nonatomic) NSString *ageString;
@property (nonatomic) NSString *region;
@property (nonatomic) NSString *avatarFilename;
@end

@implementation JYUser

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        [self save:dict];
    }
    return self;
}

- (void)save:(NSDictionary *)dict
{
    if ([dict valueForKey:@"fname"])
    {
        self.username = [dict objectForKey:@"fname"];
    }

    if ([dict valueForKey:@"fid"])
    {
        self.userId = [dict objectForKey:@"fid"];
    }

    if ([dict valueForKey:@"fyrs"])
    {
        self.yrs = [[dict objectForKey:@"fyrs"] unsignedIntegerValue];
    }

    if ([dict valueForKey:@"yrs"])
    {
        self.yrs = [[dict objectForKey:@"yrs"] unsignedIntegerValue];
    }

    if ([dict valueForKey:@"phone"])
    {
        self.phoneNumber = [[dict objectForKey:@"phone"] unsignedIntegerValue];
    }
}

- (NSString *)ageString
{
    if (self.yearOfBirth == 0)
    {
        return nil;
    }

    if (!_ageString)
    {
        NSCalendar *gregorian = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        NSInteger year = [gregorian component:NSCalendarUnitYear fromDate:NSDate.date];
        NSInteger age = year - self.yearOfBirth;
        _ageString = [NSString stringWithFormat:@"%ld", (long)age];
    }
    return _ageString;
}

- (NSString *)avatarURL
{
    return [[JYFilename sharedInstance] urlForAvatarWithRegion:self.region filename:self.avatarFilename];
}

- (NSString *)sexualOrientation
{
    if (!self.sex)
    {
        return @"X";
    }

    if (!_sexualOrientation)
    {
        if ([self.sex isEqualToString:@"M"])
        {
            _sexualOrientation = @"F";
        }
        else if ([self.sex isEqualToString:@"F"])
        {
            _sexualOrientation = @"M";
        }
        else
        {
            _sexualOrientation = @"X";
        }
    }
    return _sexualOrientation;
}

@end
