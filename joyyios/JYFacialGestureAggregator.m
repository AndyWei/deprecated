//
//  JYFacialGestureAggregator.m
//  joyyios
//
//  Created by Ping Yang on 9/15/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "JYFacialGestureAggregator.h"

@interface JYFacialGestureAggregator()
@property (nonatomic) NSMutableArray *smilesArray;
@property (nonatomic) NSMutableArray *leftBlinksArray;
@property (nonatomic) NSMutableArray *rightBlinksArray;
@property (nonatomic) NSTimer *simileGesturesCounterInvalidatorTimer;
@property (nonatomic) NSTimer *leftBlinkGesturesCounterInvalidatorTimer;
@property (nonatomic) NSTimer *rightBlinkGesturesCounterInvalidatorTimer;
@property (nonatomic) BOOL isSearchingForGesture;
@end

@implementation JYFacialGestureAggregator

const static int kNumberOfRecordsToStore = 30;
const static float kTimeNeedsToSmile = 3;
const static float kTimeNeedsToWink = 2.0f;
const static float kMaxTimeBetweenConsecutiveGesturesMutiplier = 2.0f;

#pragma mark - API

-(void)addGesture:(JYGestureType)gestureType
{
    JYFacialGesture *gesture = [JYFacialGesture facialGestureOfType:gestureType withTimeStamp:CACurrentMediaTime()];

    [self addObjectToArray:[self getArrayBasedOnJYGestureType:gestureType]
                    object:gesture
     withMaxRecordsToStore:kNumberOfRecordsToStore];
    
    //reset no gesture timer
    NSTimer *timer = [self getTimerBasedOnJYGestureType:gestureType];
    [timer invalidate];
    NSTimeInterval interval = self.samplesPerSecond * kMaxTimeBetweenConsecutiveGesturesMutiplier;
    timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                             target:self selector:@selector(noGesturesCameAfterAWhile:)
                                           userInfo:gesture
                                            repeats:NO];
    [self assignTimer:timer toJYGestureType:gestureType];
}

-(JYGestureType)checkIfRegisteredGesturesAndUpdateProgress
{
    JYGestureType gestureToReturn = JYGestureTypeNoGesture;
    
    if ([self updateProgressAndCheckIfRegisteredGesture:JYGestureTypeSmile neededTimeForGesture:kTimeNeedsToSmile])
        gestureToReturn = JYGestureTypeSmile;
    
    if ([self updateProgressAndCheckIfRegisteredGesture:JYGestureTypeLeftBlink neededTimeForGesture:kTimeNeedsToWink])
        gestureToReturn = JYGestureTypeLeftBlink;
    
    if ([self updateProgressAndCheckIfRegisteredGesture:JYGestureTypeRightBlink neededTimeForGesture:kTimeNeedsToWink])
        gestureToReturn = JYGestureTypeRightBlink;
    
    return gestureToReturn;
}

#pragma mark - Inits

-(id)init
{
	self = [super init];
	if (!self) return nil;

	self.smilesArray = [[NSMutableArray alloc] initWithCapacity:kNumberOfRecordsToStore];
    self.leftBlinksArray = [[NSMutableArray alloc] initWithCapacity:kNumberOfRecordsToStore];
    self.rightBlinksArray = [[NSMutableArray alloc] initWithCapacity:kNumberOfRecordsToStore];
    
	return self;
}

#pragma mark - Timer CallsBacks

-(void)noGesturesCameAfterAWhile:(NSTimer *)timer
{
    JYFacialGesture *gesture = (JYFacialGesture *)timer.userInfo;
	[[self getArrayBasedOnJYGestureType:gesture.type] removeAllObjects];
	[self updateProgress:0 forJYGestureType:gesture.type];
}

#pragma mark - Private

-(BOOL)updateProgressAndCheckIfRegisteredGesture:(JYGestureType)type neededTimeForGesture:(NSTimeInterval)neededTimeForGesture
{
    NSArray *gestures = [self getArrayBasedOnJYGestureType:type];
    
    if (!gestures || gestures.count == 0)
        return NO;
    
	double lastTimestamp = 0;
	double timeRangeCounter = 0;
	for (JYFacialGesture *gesture in gestures)
	{
		if (lastTimestamp == 0)//first round
		{
			lastTimestamp = gesture.timestamp;
			continue;
		}
		double timeSinceLastGesture = gesture.timestamp - lastTimestamp;
		if (timeSinceLastGesture > (self.samplesPerSecond * 4.0f))
			return NO;
		timeRangeCounter += timeSinceLastGesture;
		lastTimestamp = gesture.timestamp;
	}

    float progress = timeRangeCounter / neededTimeForGesture;
	[self updateProgress:progress forJYGestureType:type];
	return neededTimeForGesture < timeRangeCounter; //we have been gesturing for at least timeRange
}

-(void)updateProgress:(float)progress forJYGestureType:(JYGestureType)gestureType
{
	JYFacialGesture *facialGesutre = [JYFacialGesture facialGestureOfType:gestureType withTimeStamp:0];
	facialGesutre.precentForFullGesture = progress;
    [self.delegate didUpdateProgress:facialGesutre];
}

-(NSMutableArray *)getArrayBasedOnJYGestureType:(JYGestureType)gestureType
{
    NSMutableArray *array;
    if (gestureType == JYGestureTypeSmile)
    {
        array = self.smilesArray;
    }
    else if (gestureType == JYGestureTypeLeftBlink)
    {
        array = self.leftBlinksArray;
    }
    else if (gestureType == JYGestureTypeRightBlink)
    {
        array = self.rightBlinksArray;
    }
    return array;
}

-(NSTimer *)getTimerBasedOnJYGestureType:(JYGestureType)gestureType
{
    NSTimer *timer;
    if (gestureType == JYGestureTypeSmile)
    {
        timer = self.simileGesturesCounterInvalidatorTimer;
    }
    else if (gestureType == JYGestureTypeLeftBlink)
    {
        timer = self.leftBlinkGesturesCounterInvalidatorTimer;
    }
    else if (gestureType == JYGestureTypeRightBlink)
    {
        timer = self.rightBlinkGesturesCounterInvalidatorTimer;
    }
    return timer;
}

-(void)assignTimer:(NSTimer *)timer toJYGestureType:(JYGestureType)gestureType
{
    if (gestureType == JYGestureTypeSmile)
    {
        self.simileGesturesCounterInvalidatorTimer = timer;
    }
    else if (gestureType == JYGestureTypeLeftBlink)
    {
        self.leftBlinkGesturesCounterInvalidatorTimer = timer;
    }
    else if (gestureType == JYGestureTypeRightBlink)
    {
        self.rightBlinkGesturesCounterInvalidatorTimer = timer;;
    }
}

-(void)addObjectToArray:(NSMutableArray *)array object:(id)object withMaxRecordsToStore:(NSInteger)maxRecordsToStore
{
    if (array.count + 1 == maxRecordsToStore)
    {
        [array removeObjectAtIndex:0];
    }
    [array addObject:object];
}

@end
