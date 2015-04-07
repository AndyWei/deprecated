//
//  JYPanGestureRecognizer.h
//  joyyios
//
//  Created by Ping Yang on 4/2/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <MapKit/MapKit.h>

@protocol JYPanGestureRecognizerDelegate <NSObject>

@optional
- (void)panGestureBegin;
- (void)panGestureEnd;

@end


@interface JYPanGestureRecognizer : UIPanGestureRecognizer

@property(nonatomic, weak) id<JYPanGestureRecognizerDelegate> delegate;

@end
