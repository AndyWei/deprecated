//
//  NSURL+Joyy.m
//  joyyios
//
//  Created by Andy Wei on 2/20/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "NSURL+Joyy.h"

@implementation NSURL (Joyy)

+ (NSURL *)uniqueTemporaryFileURL
{
    NSString *filename = [NSString stringWithTimestampInMiliSeconds];
    return [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:filename]];
}

@end
