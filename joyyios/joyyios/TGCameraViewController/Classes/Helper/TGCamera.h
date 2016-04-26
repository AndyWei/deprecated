//
//  TGCamera.h
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

#import "JYButton.h"

@import Foundation;
@import AVFoundation;
@import UIKit;


#define kTGCameraOptionHiddenToggleButton @"TGCameraOptionHiddenToggleButton"
#define kTGCameraOptionHiddenAlbumButton @"TGCameraOptionHiddenAlbumButton"
#define kTGCameraOptionHiddenFilterButton @"TGCameraOptionHiddenFilterButton"
#define kTGCameraOptionSaveImageToAlbum @"TGCameraOptionSaveImageToAlbum"

@protocol TGCameraDelegate;



@interface TGCamera : NSObject

+ (instancetype)new __attribute__
((unavailable("[+new] is not allowed, use [+cameraWithRootView:andCaptureView:]")));

- (instancetype) init __attribute__
((unavailable("[-init] is not allowed, use [+cameraWithRootView:andCaptureView:]")));

+ (instancetype)cameraWithFlashButton:(JYButton *)flashButton;
+ (instancetype)cameraWithFlashButton:(JYButton *)flashButton devicePosition:(AVCaptureDevicePosition)devicePosition;

+ (void)setOption:(NSString*)option value:(id)value;
+ (id)getOption:(NSString*)option;

- (void)startRunning;
- (void)stopRunning;

- (AVCaptureVideoPreviewLayer *)previewLayer;
- (AVCaptureStillImageOutput *)stillImageOutput;

- (void)insertSublayerWithCaptureView:(UIView *)captureView atRootView:(UIView *)rootView;

- (void)changeFlashModeWithButton:(JYButton *)button;

- (void)captureView:(UIView *)captureView focusAtTouchPoint:(CGPoint)touchPoint;

- (void)takePhotoWithCaptureView:(UIView *)captureView
                videoOrientation:(AVCaptureVideoOrientation)videoOrientation
                        cropSize:(CGSize)cropSize
                      completion:(void (^)(UIImage *))completion;

- (void)toogleWithFlashButton:(JYButton *)flashButton;

- (BOOL)zoomToScale:(CGFloat)scale;

- (CGFloat)videoMaxZoomFactor;

@end



@protocol TGCameraDelegate <NSObject>

- (void)cameraDidCancel;
- (void)cameraDidTakePhoto:(UIImage *)image fromAlbum:(BOOL)fromAlbum withCaption:(NSString *)caption;

@optional

- (void)cameraDidSavePhotoWithError:(NSError *)error;
- (void)cameraDidSavePhotoAtPath:(NSURL *)assetURL;
- (void)cameraWillTakePhoto;

@end


@protocol TGCaptionViewControllerInterface <NSObject>

@required
@property (nonatomic) BOOL isFromAlbum;
@property (nonatomic) UIImage *photo;

@end
