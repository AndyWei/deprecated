//
//  JYFacialDetector.m
//  joyyios
//
//  Created by Ping Yang on 9/15/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFacialGesturesDetector.h"
#import "JYFacialGesture.h"
#import "UIDevice+ExifOrientation.h"
#import "JYFacialGestureAggregator.h"
#import "JYFacialGestureCameraCapturer.h"

@interface JYFacialGesturesDetector () <JYFacialGestureCameraCapturerDelegate, JYFacialGestureAggregatorDelegte>
@property (nonatomic) CIDetector *faceDetector;
@property (nonatomic) CIImage *currentImage;
@property (nonatomic) JYFacialGestureCameraCapturer *cameraCapturer;
@property (nonatomic) JYFacialGestureAggregator *gestureAggregator;
@end

//  if this value is too low it takes a lot of CPU, if too high the effect is bad cause detection is not happening a lot.
const NSTimeInterval kSamplesPerSecond = 0.3f;

@implementation JYFacialGesturesDetector

- (id)init
{
    self = [super init];
    if (self)
    {
		self.gestureAggregator = [JYFacialGestureAggregator new];
        self.gestureAggregator.samplesPerSecond = kSamplesPerSecond;
        self.gestureAggregator.delegate = self;
		self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
											 context:nil
											 options:@{CIDetectorAccuracy : CIDetectorAccuracyLow}];
        self.cameraCapturer = [JYFacialGestureCameraCapturer new];
        self.cameraCapturer.delegate = self;
        
    }
    return self;
}

- (void)startDetection:(NSError **)error
{
    [self.cameraCapturer setAVCaptureAtSampleRate:kSamplesPerSecond withCameraPreviewView:self.cameraPreviewView withError:error];
}

- (void)stopDetection
{
    self.currentImage = nil;
	[self.cameraCapturer teardownAVCapture];
}

#pragma mark - Camera Capturer Delegate

- (void)imageFromCamera:(CIImage *)image isUsingFrontCamera:(BOOL)isUsingFrontCamera
{
    ExifForOrientationType exifOrientation = [[UIDevice currentDevice] exifForCurrentOrientationWithFrontCamera:isUsingFrontCamera];
    
    NSDictionary *detectionOtions = @{ CIDetectorImageOrientation:@(exifOrientation),
                                       CIDetectorSmile:@NO,
                                       CIDetectorEyeBlink:@YES,
                                       CIDetectorAccuracy:CIDetectorAccuracyLow
                                       
                                       };

    NSArray *features = [self.faceDetector featuresInImage:image
                                                   options:detectionOtions];
    self.currentImage = image;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self extractFacialGesturesFromFeatures:features];
    });
}

#pragma mark - Aggregator Delegte
- (void)didUpdateProgress:(JYFacialGesture *)gesture
{
    [self.delegate didUpdateProgress:gesture.precentForFullGesture forType:gesture.type];
}

#pragma mark - Private

- (void)extractFacialGesturesFromFeatures:(NSArray *)features
{
	for ( CIFaceFeature *faceFeature in features )
	{
	    if (faceFeature.hasSmile)
        {
			[self.gestureAggregator addGesture:JYGestureTypeSmile];
		}
		if (faceFeature.leftEyeClosed)
		{
			[self.gestureAggregator addGesture:JYGestureTypeLeftBlink];
		}
		if (faceFeature.rightEyeClosed)
		{
			[self.gestureAggregator addGesture:JYGestureTypeRightBlink];
		}
	}
	JYGestureType registeredGestured = [self.gestureAggregator checkIfRegisteredGesturesAndUpdateProgress];
	if (registeredGestured == JYGestureTypeNoGesture)
		return;

	UIImage *currentImage = [UIImage imageWithCIImage:self.currentImage scale:1 orientation:UIImageOrientationLeftMirrored];

    [self.delegate didRegisterFacialGesutreOfType:registeredGestured withLastImage:currentImage];
}

@end
