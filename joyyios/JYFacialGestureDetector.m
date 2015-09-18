//
//  JYFacialGestureDetector.m
//  joyyios
//
//  Created by Ping Yang on 9/15/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFacialGestureCamera.h"
#import "JYFacialGestureDetector.h"

@interface JYFacialGestureDetector () <JYFacialGestureCameraDelegate>
@property (nonatomic) CIDetector *faceDetector;
@property (nonatomic) JYFacialGestureCamera *camera;
@property (nonatomic) CFTimeInterval lastReportingTimestamp;
@property (nonatomic) CFTimeInterval lastBlinkTimestamp;
@end

// How fast a guesture can be captured. shorter means more CPU
const CFTimeInterval kSamplePeriod = 0.2f;

// Prevent a blink from being parsed as wink
const CFTimeInterval kBlinkMutePeriod = 0.5f;

// To avoid one actual guesture being mapped to multi
const CFTimeInterval kReportingPeriod = 1.2f;


@implementation JYFacialGestureDetector

- (id)init
{
    self = [super init];
    if (self)
    {
        NSDictionary *options = @{CIDetectorAccuracy : CIDetectorAccuracyHigh};

        self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                               context:nil
											 options:options];

        self.camera = [JYFacialGestureCamera new];
        self.camera.delegate = self;
        self.detectSmile = self.detectLeftWink = self.detectRightWink = NO;
    }
    return self;
}

- (void)startDetectionWithError:(NSError **)error
{
    self.lastReportingTimestamp = 0.0f;
    self.lastBlinkTimestamp= 0.0f;
    [self.camera startWithPeriod:kSamplePeriod previewView:self.previewView withError:error];
}

- (void)stopDetection
{
	[self.camera stop];
}

#pragma mark - JYFacialGestureCameraDelegate methods

// Note: This method will be invoked from camera video output queue, not the main thread
- (void)camera:(JYFacialGestureCamera *)camera didCaptureImage:(CIImage *)image isFront:(BOOL)isFrontCamera
{
    if (![self _shouldReport])
    {
        return;
    }

    id orientation = nil;
    if([[image properties] valueForKey:(NSString *)kCGImagePropertyOrientation] == nil)
    {
        orientation = [NSNumber numberWithInt:6];
    }
    else
    {
        orientation = [[image properties] valueForKey:(NSString *)kCGImagePropertyOrientation];
    }

    id detectSmile = self.detectSmile? @(YES): @(NO);
    id detectBlink = (self.detectLeftWink || self.detectRightWink)? @(YES): @(NO);

    NSDictionary *detectionOtions = @{ CIDetectorImageOrientation:orientation,
                                       CIDetectorSmile:detectSmile,
                                       CIDetectorEyeBlink:detectBlink
                                       };

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_async(queue, ^(void){

        // This operation will take about 0.15 seconds on iPhone6
        NSArray *features = [self.faceDetector featuresInImage:image options:detectionOtions];

        if (features.count == 0)
        {
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self _handleFeatures:features];
        });
    });
}

#pragma mark - Private

- (BOOL)_shouldReport
{
    if (![self.delegate isListening])
    {
        return NO;
    }

    CFTimeInterval now = CACurrentMediaTime();
    CFTimeInterval reportTimePassed = now - self.lastReportingTimestamp;
    CFTimeInterval blinkTimePassed = now - self.lastBlinkTimestamp;

    return (blinkTimePassed >= kBlinkMutePeriod && reportTimePassed >= kReportingPeriod);
}

- (void)_handleFeatures:(NSArray *)features
{
    // Since it takes some time for getting features from image, the report condition might have been changed
    // Double check here to avoid unneccessary calls
    if (![self _shouldReport])
    {
        return;
    }

    // only handle the first one, which has highest confidence
    CIFaceFeature *faceFeature = features[0];

    if (faceFeature.hasSmile)
    {
        NSLog(@"Detected smile");
        self.lastReportingTimestamp = CACurrentMediaTime();
        if ([self.delegate respondsToSelector:@selector(detectorDidDetectSmile:)])
        {
            [self.delegate detectorDidDetectSmile:self];
        }
    }

    if (faceFeature.leftEyeClosed && faceFeature.rightEyeClosed)
    {
        NSLog(@"Detected blink");

        self.lastBlinkTimestamp = CACurrentMediaTime();
        // Blink is not left or right wink, so return now
        return;
    }

    // Note: left and right eye here are from camera view, not the user's
    // So faceFeature.rightEyeClosed actually means the user's left eye is closed, which is defined as left wink
    if (faceFeature.rightEyeClosed)
    {
        NSLog(@"Detected left wink");
        self.lastReportingTimestamp = CACurrentMediaTime();

        if ([self.delegate respondsToSelector:@selector(detectorDidDetectLeftWink:)])
        {
            [self.delegate detectorDidDetectLeftWink:self];
        }
    }
    else if (faceFeature.leftEyeClosed)
    {
        NSLog(@"Detected right wink");
        self.lastReportingTimestamp = CACurrentMediaTime();

        if ([self.delegate respondsToSelector:@selector(detectorDidDetectRightWink:)])
        {
            [self.delegate detectorDidDetectRightWink:self];
        }
    }
}

@end
