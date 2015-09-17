//
//  JYFacialDetector.m
//  joyyios
//
//  Created by Ping Yang on 9/15/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFacialGestureCamera.h"
#import "JYFacialGesturesDetector.h"

@interface JYFacialGesturesDetector () <JYFacialGestureCameraDelegate>
@property (nonatomic) CIDetector *faceDetector;
@property (nonatomic) CIImage *currentImage;
@property (nonatomic) JYFacialGestureCamera *camera;
@property (nonatomic) dispatch_queue_t detectorQueue;
@end

//  if this value is too low it takes a lot of CPU, if too high the effect is bad cause detection is not happening a lot.
const CFTimeInterval kCapturePeriod = 0.25f;

@implementation JYFacialGesturesDetector

- (id)init
{
    self = [super init];
    if (self)
    {
		self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
											 context:nil
											 options:@{CIDetectorAccuracy : CIDetectorAccuracyLow}];

        self.camera = [JYFacialGestureCamera new];
        self.camera.delegate = self;
        self.detectSmile = self.detectBlink = self.detectLeftWink = self.detectRightWink = NO;
        self.detectorQueue = dispatch_queue_create("facial_gesture_detector_queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)startDetectionWithError:(NSError **)error
{
    [self.camera startWithPeriod:kCapturePeriod previewView:self.previewView withError:error];
}

- (void)stopDetection
{
    self.currentImage = nil;
	[self.camera stop];
}

#pragma mark - JYFacialGestureCameraDelegate methods

// Note: This method will be invoked from camera video output queue, not the main thread
- (void)camera:(JYFacialGestureCamera *)camera didCaptureImage:(CIImage *)image isFront:(BOOL)isFrontCamera
{
    if (![self.delegate isListening])
    {
        // The delegate is not interested in the detect results, just return to save CPU and RAM
//        NSLog(@"Camera get image, but the delegate is not listening");
        return;
    }

    id orientation = nil;
    if([[image properties] valueForKey:(NSString *)kCGImagePropertyOrientation] == nil)
    {
        orientation = [NSNumber numberWithInt:5];
    }
    else
    {
        orientation = [[image properties] valueForKey:(NSString *)kCGImagePropertyOrientation];
    }

    id detectSmile = self.detectSmile? @YES: @NO;
    id detectBlink = (self.detectBlink || self.detectLeftWink || self.detectRightWink)? @YES: @NO;

    NSDictionary *detectionOtions = @{ CIDetectorImageOrientation:orientation,
                                       CIDetectorSmile:detectSmile,
                                       CIDetectorEyeBlink:detectBlink,
                                       CIDetectorAccuracy:CIDetectorAccuracyHigh
                                       };

//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
    dispatch_async(self.detectorQueue, ^(void){
        NSArray *features = [self.faceDetector featuresInImage:image options:detectionOtions];

        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self _handleFeatures:features];
        });
    });

    self.currentImage = image;
}

#pragma mark - Private

- (void)_handleFeatures:(NSArray *)features
{
    // Since it take some time for getting feature from image, the delegate may not be listening now.
    // So double check here to avoid unneccessary calls
    if (![self.delegate isListening])
    {
        NSLog(@"Detector get features, but the delegate is not listening");
        return;
    }

    for (CIFaceFeature *faceFeature in features)
    {
        if (faceFeature.hasSmile)
        {
            NSLog(@"Detected smile");
            if ([self.delegate respondsToSelector:@selector(detectorDidDetectSmile:)])
            {
                [self.delegate detectorDidDetectSmile:self];
            }
        }

        if (faceFeature.leftEyeClosed && faceFeature.rightEyeClosed)
        {
            NSLog(@"Detected blink");
            if ([self.delegate respondsToSelector:@selector(detectorDidDetectBlink:)])
            {
                [self.delegate detectorDidDetectBlink:self];
            }

            // Blink is not left or right wink
            return;
        }

        if (faceFeature.leftEyeClosed)
        {
            NSLog(@"Detected left wink");
            if ([self.delegate respondsToSelector:@selector(detectorDidDetectLeftWink:)])
            {
                [self.delegate detectorDidDetectLeftWink:self];
            }
        }
        else if (faceFeature.rightEyeClosed)
        {
            NSLog(@"Detected right wink");
            if ([self.delegate respondsToSelector:@selector(detectorDidDetectRightWink:)])
            {
                [self.delegate detectorDidDetectRightWink:self];
            }
        }
    }
}

@end
