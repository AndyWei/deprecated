//
//  JYPhotoName.m
//  joyyios
//
//  Created by Ping Yang on 7/11/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYPhotoName.h"
#import "JYUser.h"

@implementation JYPhotoName

+ (NSString *)name
{
    NSString *first = [[JYUser currentUser].username substringToIndex:1];  // "j" for jack

    u_int32_t rand = arc4random_uniform(10000);                            // 176
    NSString *randString = [NSString stringWithFormat:@"%04d", rand];      // "0176"

    NSString *timestamp = [JYPhotoName _timeInMiliSeconds];                // 458354045799

    NSString *photoName = [NSString stringWithFormat:@"%@%@_%@.jpg", first, randString, timestamp]; // "j0176_458354045799.jpg"
    return photoName;

}

+ (NSString *)_timeInMiliSeconds
{
    long long timestamp = [@(floor([NSDate timeIntervalSinceReferenceDate] * 1000)) longLongValue];
    return [NSString stringWithFormat:@"%lld",timestamp];
}

@end
