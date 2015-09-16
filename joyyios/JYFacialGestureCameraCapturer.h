//
//  JYFacialGestureCameraCapturer.h
//  joyyios
//
//  Created by Ping Yang on 9/15/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@class CIImage;

@protocol JYFacialGestureCameraCapturerDelegate <NSObject>

- (void)imageFromCamera:(CIImage *)ciImage isUsingFrontCamera:(BOOL)isUsingFrontCamera;

@end


@interface JYFacialGestureCameraCapturer : NSObject

- (void)setAVCaptureAtSampleRate:(float)sampleRate withCameraPreviewView:(UIView *)cameraPreviewView withError:(NSError **)error;
- (void)teardownAVCapture;

@property (nonatomic, weak) id<JYFacialGestureCameraCapturerDelegate> delegate;

@end
