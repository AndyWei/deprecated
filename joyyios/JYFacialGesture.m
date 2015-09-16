//
//  JYFacialGesture.m
//  joyyios
//
//  Created by Ping Yang on 9/15/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFacialGesture.h"

@implementation JYFacialGesture

+(JYFacialGesture *)facialGestureOfType:(JYGestureType)type withTimeStamp:(NSTimeInterval)timestamp
{
	JYFacialGesture *newGesture = [JYFacialGesture new];

	newGesture.type = type;
	newGesture.timestamp = timestamp;

	return newGesture;
}

+(NSString *)gestureTypeToString:(JYGestureType)type
{
    NSString *typString;
    switch (type) {
        case JYGestureTypeSmile:
            typString = @"Smiling";
            break;
        case JYGestureTypeLeftBlink:
            typString = @"Left Blink";
            break;
        case JYGestureTypeRightBlink:
            typString = @"Rigt Blink";
            break;
        case JYGestureTypeNoGesture:
            typString = @"No Gesture";
        default:
            typString = @"No Gesture - Default";
            break;
    }
    return typString;
}

@end
