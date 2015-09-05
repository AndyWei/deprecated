//
//  JYPerson.m
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//


@interface JYPerson ()
@end

@implementation JYPerson
@synthesize ageString = _ageString;
@synthesize idString = _idString;
@synthesize avatarURL = _avatarURL;
@synthesize fullAvatarURL = _fullAvatarURL;

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
        _bio  = [dict objectForKey:@"bio"];
        _name = [dict objectForKey:@"username"];
        _org  = [dict objectForKey:@"org"];
        _friendCount = [dict unsignedIntegerValueForKey:@"friends"];
        _gender      = [dict unsignedIntegerValueForKey:@"gender"];
        _heartCount  = [dict unsignedIntegerValueForKey:@"hearts"];
        _orgType     = [dict unsignedIntegerValueForKey:@"orgtype"];
        _personId    = [dict unsignedIntegerValueForKey:@"id"];
        _score       = [dict unsignedIntegerValueForKey:@"score"];
        _yearOfBirth = [dict unsignedIntegerValueForKey:@"yob"];
    }
    return self;
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
    if (!_avatarURL)
    {
        _avatarURL = [NSString stringWithFormat:@"%@%@_s.jpg", kURLAvatarBase, self.name];
    }
    return _avatarURL;
}

- (NSString *)fullAvatarURL
{
    return [NSString stringWithFormat:@"%@%@.jpg", kURLAvatarBase, self.name];
}

@end
