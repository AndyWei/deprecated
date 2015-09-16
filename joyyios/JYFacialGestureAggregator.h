//
//  JYFacialGestureAggregator.h
//  joyyios
//
//  Created by Ping Yang on 9/15/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFacialGesture.h"

@protocol JYFacialGestureAggregatorDelegte <NSObject>
-(void)didUpdateProgress:(JYFacialGesture *)gesture;
@end


@interface JYFacialGestureAggregator : NSObject

- (void)addGesture:(JYGestureType)gestureType;
- (JYGestureType)checkIfRegisteredGesturesAndUpdateProgress;

@property (nonatomic) NSTimeInterval samplesPerSecond;
@property (nonatomic, weak) id<JYFacialGestureAggregatorDelegte> delegate;

@end
