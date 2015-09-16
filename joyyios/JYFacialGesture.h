//
//  JYFacialGesture.h
//  joyyios
//
//  Created by Ping Yang on 9/15/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

typedef NS_ENUM(NSUInteger , JYGestureType)
{
	JYGestureTypeNoGesture,
    JYGestureTypeSmile,
	JYGestureTypeLeftBlink,
	JYGestureTypeRightBlink
};

@interface JYFacialGesture : NSObject

@property (nonatomic, readwrite) JYGestureType type;
@property (nonatomic, readwrite) NSTimeInterval timestamp;
@property (nonatomic, readwrite) float precentForFullGesture;

+(JYFacialGesture *)facialGestureOfType:(JYGestureType)type withTimeStamp:(NSTimeInterval)timestamp;

+(NSString *)gestureTypeToString:(JYGestureType)type;

@end
