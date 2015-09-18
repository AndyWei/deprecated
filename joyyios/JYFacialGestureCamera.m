//
//  JYFacialGestureCameraCapturer.m
//  joyyios
//
//  Created by Ping Yang on 9/15/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "JYFacialGestureCamera.h"

@interface JYFacialGestureCamera() <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic) AVCaptureVideoPreviewLayer *layer;
@property (nonatomic) BOOL isUsingFrontCamera;
@property (nonatomic) CFTimeInterval lastSampleTimestamp;
@property (nonatomic) CFTimeInterval stampPeriod;
@property (nonatomic) dispatch_queue_t videoDataOutputQueue;
@end


@implementation JYFacialGestureCamera

- (void)startWithPeriod:(CFTimeInterval)period previewView:(UIView *)previewView withError:(NSError **)error
{
    self.stampPeriod = period;
    self.session = [AVCaptureSession new];
    self.session.sessionPreset = AVCaptureSessionPreset352x288;
    AVCaptureDeviceInput *deviceInput = [self _captureDeviceInput:error];
    
    if (*error)
    {
        [self stop];
        return;
    }

    if ([self.session canAddInput:deviceInput])
    {
        [self.session addInput:deviceInput];
    }

    // The serial dispatch queue used for the sample buffer delegate
    self.videoDataOutputQueue = dispatch_queue_create("video_data_output_queue", DISPATCH_QUEUE_SERIAL);

    self.videoDataOutput = [AVCaptureVideoDataOutput new];
    
    // BGRA is the best for accuracy and CPU
    self.videoDataOutput.videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey:@(kCMPixelFormat_32BGRA) };

    // TODO: currently no issue, but need investigate the impact of this setting
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
    
    if ( [self.session canAddOutput:self.videoDataOutput] )
    {
        [self.session addOutput:self.videoDataOutput];
    }

    // Get the output for doing face detection.
    [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];

    if (previewView)
    {
        self.layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        self.layer.backgroundColor = [[UIColor blackColor] CGColor];
        self.layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        CALayer *rootLayer = previewView.layer;
        rootLayer.masksToBounds = YES;
        self.layer.frame = rootLayer.bounds;
        [rootLayer addSublayer:self.layer];
    }

    self.lastSampleTimestamp = 0.0f;
    [self.session startRunning];
}

- (void)stop
{
    self.videoDataOutput = nil;
    self.videoDataOutputQueue = nil;

    if (self.layer)
    {
        [self.layer removeFromSuperlayer];
        self.layer = nil;
    }

    self.session = nil;
}

- (AVCaptureDeviceInput *)_captureDeviceInput:(NSError **)error;
{
    AVCaptureDevice *device;
    
    AVCaptureDevicePosition desiredPosition = AVCaptureDevicePositionFront;
    
    // Find the front facing camera
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
    {
        if (d.position == desiredPosition) {
            device = d;
            self.isUsingFrontCamera = YES;
            break;
        }
    }

    // Fall back to the default camera
    if (!device)
    {
        self.isUsingFrontCamera = NO;
        device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }

    return [AVCaptureDeviceInput deviceInputWithDevice:device error:error];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CFTimeInterval now = CACurrentMediaTime();
    CFTimeInterval timePassed = now - self.lastSampleTimestamp;

    if (timePassed < self.stampPeriod)
    {
        return;
    }

    self.lastSampleTimestamp = now;
    
    // Get the image from sample buffer
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];

    if ([self.delegate respondsToSelector:@selector(camera:didCaptureImage:isFront:)])
    {
        [self.delegate camera:self didCaptureImage:image isFront:self.isUsingFrontCamera];
    }
}

@end
