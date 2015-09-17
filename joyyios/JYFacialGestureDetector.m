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
@end

const CFTimeInterval kCapturePeriod = 0.15f;

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
        self.detectSmile = self.detectBlink = self.detectLeftWink = self.detectRightWink = NO;
        self.reportingPeriod = 1.5f;
        self.lastReportingTimestamp = 0.0f;
    }
    return self;
}

- (void)startDetectionWithError:(NSError **)error
{
    self.lastReportingTimestamp = 0.0f;
    [self.camera startWithPeriod:kCapturePeriod previewView:self.previewView withError:error];
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
        orientation = [NSNumber numberWithInt:5];
    }
    else
    {
        orientation = [[image properties] valueForKey:(NSString *)kCGImagePropertyOrientation];
    }

    id detectSmile = self.detectSmile? @(YES): @(NO);
    id detectBlink = (self.detectBlink || self.detectLeftWink || self.detectRightWink)? @(YES): @(NO);

    NSDictionary *detectionOtions = @{ CIDetectorImageOrientation:orientation,
                                       CIDetectorSmile:detectSmile,
                                       CIDetectorEyeBlink:detectBlink
                                       };

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_async(queue, ^(void){

//        NSLog(@"immage: %lu begin", (unsigned long)image);
        NSArray *features = [self.faceDetector featuresInImage:image options:detectionOtions];
//        NSLog(@"immage: %lu end", (unsigned long)image);

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
        //        NSLog(@"Camera get image, but the delegate is not listening");
        return NO;
    }

    CFTimeInterval now = CACurrentMediaTime();
    CFTimeInterval timePassed = now - self.lastReportingTimestamp;

    return (timePassed >= self.reportingPeriod);
}

- (void)_handleFeatures:(NSArray *)features
{
    if (features.count == 0)
    {
        return;
    }

    // Since it takes some time for getting features from image, the report condition might have been changed, double check here to avoid unneccessary calls
    if (![self _shouldReport])
    {
        return;
    }

    CIFaceFeature *faceFeature = features[0]; // only handle the first one

    self.lastReportingTimestamp = CACurrentMediaTime();

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

        // Blink is not left or right wink, so return now
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

@end
