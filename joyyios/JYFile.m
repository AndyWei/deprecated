//
//  JYFile.m
//  joyyios
//
//  Created by Ping Yang on 9/2/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFile.h"

@implementation JYFile

+ (NSString *)filenameWithHttpContentType:(NSString *)contentType
{
    NSString *suffix = @"unknown";
    if ([contentType isEqualToString:kContentTypeJPG])
    {
        suffix = @"jpg";
    }
    return [JYFile filenameWithSuffix:suffix];
}

+ (NSString *)filenameWithSuffix:(NSString *)suffix
{
    NSString *first = [[JYCredential currentCredential].username substringToIndex:1];  // "j" for jack

    u_int32_t rand = arc4random_uniform(10000);                        // 176
    NSString *randString = [NSString stringWithFormat:@"%04d", rand];  // "0176"

    NSString *timestamp = [JYFile timeInMiliSeconds];                // 458354045799

    return [NSString stringWithFormat:@"%@%@_%@.%@", first, randString, timestamp, suffix]; // "j0176_458354045799.jpg"
}

+ (NSString *)timeInMiliSeconds
{
    long long timestamp = [@(floor([NSDate timeIntervalSinceReferenceDate] * 1000)) longLongValue];
    return [NSString stringWithFormat:@"%lld",timestamp];
}

@end
