//
//  TGCamera.m
//  TGCameraViewController
//
//  Created by Bruno Tortato Furtado on 14/09/14.
//  Copyright (c) 2014 Tudo Gostoso Internet. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "TGCamera.h"
#import "TGCameraFlash.h"
#import "TGCameraFocusView.h"
#import "TGCameraShot.h"
#import "TGCameraToggle.h"

NSMutableDictionary *optionDictionary;


@interface TGCamera ()

@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;

+ (instancetype)newCamera;
+ (void)initOptions;

- (void)setupWithFlashButton:(JYButton *)flashButton;

@end



@implementation TGCamera

+ (instancetype)cameraWithFlashButton:(JYButton *)flashButton
{
    TGCamera *camera = [TGCamera newCamera];
    [camera setupWithFlashButton:flashButton];
    
    return camera;
}

+ (instancetype)cameraWithFlashButton:(JYButton *)flashButton devicePosition:(AVCaptureDevicePosition)devicePosition
{
    TGCamera *camera = [TGCamera newCamera];
    [camera setupWithFlashButton:flashButton devicePosition:devicePosition];
    
    return camera;
}


+ (void)setOption:(NSString *)option value:(id)value
{
    if (optionDictionary == nil) {
        [TGCamera initOptions];
    }
    
    if (option != nil && value != nil) {
        optionDictionary[option] = value;
    }
}

 + (id)getOption:(NSString *)option
{
    if (optionDictionary == nil) {
        [TGCamera initOptions];
    }
    
    if (option != nil) {
        return optionDictionary[option];
    }
    
    return nil;
}

- (void)dealloc
{
    _session = nil;
    _previewLayer = nil;
    _stillImageOutput = nil;
}

#pragma mark -
#pragma mark - Public methods

- (void)startRunning
{
    [_session startRunning];
}

- (void)stopRunning
{
    [_session stopRunning];
}

- (void)insertSublayerWithCaptureView:(UIView *)captureView atRootView:(UIView *)rootView
{
    if (_previewLayer)
    {
        return;
    }

    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    CGRect frame = captureView.frame;
    _previewLayer.frame = frame;

    CALayer *rootLayer = [rootView layer];
    [rootLayer insertSublayer:_previewLayer atIndex:0];
}

- (void)changeFlashModeWithButton:(JYButton *)button
{
    [TGCameraFlash changeModeWithCaptureSession:_session andButton:button];
}

- (void)captureView:(UIView *)captureView focusAtTouchPoint:(CGPoint)touchPoint
{
    AVCaptureDevice *device = [_session.inputs.lastObject device];

    [self showFocusAnimationOnView:captureView withTouchPoint:touchPoint];

    if ([device lockForConfiguration:nil]) {

        CGPoint pointOfInterest = [self pointOfInterestWithTouchPoint:touchPoint onView:captureView];
        if (device.focusPointOfInterestSupported) {
            device.focusPointOfInterest = pointOfInterest;
        }

        if (device.exposurePointOfInterestSupported) {
            device.exposurePointOfInterest = pointOfInterest;
        }

        if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }

        if ([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }

        [device unlockForConfiguration];
    }
}

- (void)takePhotoWithCaptureView:(UIView *)captureView videoOrientation:(AVCaptureVideoOrientation)videoOrientation cropSize:(CGSize)cropSize completion:(void (^)(UIImage *))completion
{
    [TGCameraShot takePhotoCaptureView:captureView stillImageOutput:_stillImageOutput videoOrientation:videoOrientation cropSize:cropSize
    completion:^(UIImage *photo) {
        completion(photo);
    }];
}

- (void)toogleWithFlashButton:(JYButton *)flashButton
{
    [TGCameraToggle toogleWithCaptureSession:_session];
    [TGCameraFlash flashModeWithCaptureSession:_session andButton:flashButton];
}

#pragma mark -
#pragma mark - Private methods

- (void)showFocusAnimationOnView:(UIView *)view withTouchPoint:(CGPoint)touchPoint
{
    //
    // add focus view animated
    //
    TGCameraFocusView *focusView = [[TGCameraFocusView alloc] initWithFrame:CGRectMake(0, 0, TGCameraFocusSize, TGCameraFocusSize)];
    focusView.center = touchPoint;
    [view addSubview:focusView];
    [focusView startAnimation];

    dispatch_time_t focusTime = dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC);
    dispatch_after(focusTime, dispatch_get_main_queue(), ^(void){
        [focusView stopAnimation];
    });
}

- (CGPoint)pointOfInterestWithTouchPoint:(CGPoint)touchPoint onView:(UIView *)view
{
    CGPoint pointOfInterest = CGPointMake(0.5f, 0.5f);
    CGSize frameSize = [view frame].size;

    for (AVCaptureInputPort *port in [[[_session inputs] lastObject] ports]) {
        if ([port mediaType] == AVMediaTypeVideo) {

            CGRect cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], NO);
            CGSize apertureSize = cleanAperture.size;
            CGPoint point = touchPoint;

            CGFloat apertureRatio = apertureSize.height / apertureSize.width;
            CGFloat viewRatio = frameSize.width / frameSize.height;
            CGFloat xc = .5f;
            CGFloat yc = .5f;

            if (viewRatio > apertureRatio) {
                CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
                yc = (frameSize.width - point.x) / frameSize.width;
            } else {
                CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                xc = point.y / frameSize.height;
            }
            pointOfInterest = CGPointMake(xc, yc);
        }
    }
    
    return pointOfInterest;
}

+ (instancetype)newCamera
{
    return [super new];
}

- (void)setupWithFlashButton:(JYButton *)flashButton
{
    //
    // create session
    //
    
    _session = [AVCaptureSession new];
    _session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    //
    // setup device
    //
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ([device lockForConfiguration:nil]) {
        
        if([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }

        device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;

        [device unlockForConfiguration];
    }

    //
    // add device input to session
    //
    
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    [_session addInput:deviceInput];
    
    //
    // add output to session
    //
    
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    
    _stillImageOutput = [AVCaptureStillImageOutput new];
    _stillImageOutput.outputSettings = outputSettings;
    
    [_session addOutput:_stillImageOutput];
    
    //
    // setup flash button
    //
    
    [TGCameraFlash flashModeWithCaptureSession:_session andButton:flashButton];
}

- (void)setupWithFlashButton:(JYButton *)flashButton devicePosition:(AVCaptureDevicePosition)devicePosition
{
    //
    // create session
    //
    
    _session = [AVCaptureSession new];
    _session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    //
    // setup device
    //
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device;
    for (AVCaptureDevice *aDevice in devices) {
        if (aDevice.position == devicePosition) {
            device = aDevice;
        }
    }
    if (!device) {
        device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    if ([device lockForConfiguration:nil]) {
        
        if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
        
        device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        
        [device unlockForConfiguration];
    }
    
    //
    // add device input to session
    //
    
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    [_session addInput:deviceInput];
    
    //
    // add output to session
    //
    
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    
    _stillImageOutput = [AVCaptureStillImageOutput new];
    _stillImageOutput.outputSettings = outputSettings;
    
    [_session addOutput:_stillImageOutput];
    
    //
    // setup flash button
    //
    
    [TGCameraFlash flashModeWithCaptureSession:_session andButton:flashButton];
}

+ (void)initOptions
{
    optionDictionary = [NSMutableDictionary dictionary];
}

@end