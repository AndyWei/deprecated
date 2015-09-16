//
//  JYFacialDetector.h
//  joyyios
//
//  Created by Ping Yang on 9/15/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFacialGesture.h"

@protocol JYFacialDetectorDelegate <NSObject>

- (void)didRegisterFacialGesutreOfType:(JYGestureType)facialJYGestureType withLastImage:(UIImage *)lastImage;
@optional
- (void)didUpdateProgress:(float)progress forType:(JYGestureType)facialJYGestureType;

@end

@interface JYFacialGesturesDetector : NSObject

- (void)startDetection:(NSError **)error;
- (void)stopDetection;

@property (nonatomic, weak) id<JYFacialDetectorDelegate> delegate;

/**
 *  UIView displaying the camera output, default is nil with no output.
 */
@property (nonatomic, weak) UIView *cameraPreviewView;

@end
