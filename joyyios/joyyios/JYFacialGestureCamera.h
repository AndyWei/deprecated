//
//  JYFacialGestureCameraCapturer.h
//  joyyios
//
//  Created by Ping Yang on 9/15/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@class CIImage;
@class JYFacialGestureCamera;

@protocol JYFacialGestureCameraDelegate <NSObject>

- (void)camera:(JYFacialGestureCamera *)camera didCaptureImage:(CIImage *)image isFront:(BOOL)isFrontCamera;

@end


@interface JYFacialGestureCamera : NSObject

- (void)startWithPeriod:(CFTimeInterval)period previewView:(UIView *)previewView withError:(NSError **)error;
- (void)stop;

@property (nonatomic, weak) id<JYFacialGestureCameraDelegate> delegate;

@end
