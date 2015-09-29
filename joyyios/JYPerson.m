//
//  JYPerson.m
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFilename.h"

@interface JYPerson ()
@property (nonatomic) NSString *idString;
@property (nonatomic) NSString *ageString;
@property (nonatomic) NSString *region;
@property (nonatomic) NSString *avatarFilename;
@end

@implementation JYPerson

+ (JYPerson *)me
{
    static JYPerson *_me;
    static dispatch_once_t done;
    dispatch_once(&done, ^{
        _me = [JYPerson new];

        // TODO: read from KV store and fetch from server if no local information
    });
    return _me;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        _username       = [dict objectForKey:@"username"];
        _sex            = [dict objectForKey:@"sex"];
        _region         = [dict objectForKey:@"reg"];
        _avatarFilename = [dict objectForKey:@"fn"];
        _bio            = [dict objectForKey:@"bio"];
        _personId    = [dict unsignedIntegerValueForKey:@"id"];
        _friendCount = [dict unsignedIntegerValueForKey:@"fcnt"];
        _winkCount   = [dict unsignedIntegerValueForKey:@"wcnt"];
        _score       = [dict unsignedIntegerValueForKey:@"score"];
        _yearOfBirth = [dict unsignedIntegerValueForKey:@"yob"];
    }
    return self;
}

- (void)save:(NSDictionary *)dict
{
    if ([dict valueForKey:@"username"])
    {
        self.username = [dict valueForKey:@"username"];
    }

    if ([dict valueForKey:@"reg"])
    {
        self.region = [dict valueForKey:@"reg"];
    }

    if ([dict valueForKey:@"fn"])
    {
        self.avatarFilename = [dict valueForKey:@"fn"];
    }

    if ([dict valueForKey:@"sex"])
    {
        self.sex = [dict valueForKey:@"sex"];
    }

    if ([dict valueForKey:@"yob"])
    {
        self.yearOfBirth = [dict unsignedIntegerValueForKey:@"yob"];
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

- (NSString *)idString
{
    if (!_idString)
    {
        _idString = [NSString stringWithFormat:@"%tu", self.personId];
    }
    return _idString;
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
