//
//  TGCameraViewController.m
//  TGCameraViewController
//
//  Created by Bruno Tortato Furtado on 13/09/14.
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
#import "TGCameraColor.h"
#import "TGCameraGridView.h"
#import "TGCameraViewController.h"
#import "TGTintedButton.h"

@interface TGCameraViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic) CGFloat currentScale;
@property (nonatomic) CGFloat lastScale;
@property (nonatomic) CGFloat maxScale;
@property (nonatomic) TGTintedButton *albumButton;
@property (nonatomic) JYButton *closeButton;
@property (nonatomic) JYButton *flashButton;
@property (nonatomic) JYButton *gridButton;
@property (nonatomic) JYButton *shotButton;
@property (nonatomic) JYButton *toggleButton;
@property (nonatomic) TGCamera *camera;
@property (nonatomic) TGCameraGridView *gridView;
@property (nonatomic) UIColor *toggleOnColor;
@property (nonatomic) UIColor *toggleOffColor;
@property (nonatomic) UIView *captureView;
@end

@implementation TGCameraViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = JoyyBlack;

    [self.view addSubview:self.albumButton];
    [self.view addSubview:self.captureView];
    [self.view addSubview:self.closeButton];
    [self.view addSubview:self.flashButton];
    [self.view addSubview:self.gridButton];
    [self.view addSubview:self.shotButton];
    [self.view addSubview:self.toggleButton];
    [self.captureView addSubview:self.gridView];

    NSDictionary *views = @{
                            @"albumButton": self.albumButton,
                            @"captureView": self.captureView,
                            @"closeButton": self.closeButton,
                            @"flashButton": self.flashButton,
                            @"gridButton": self.gridButton,
                            @"shotButton": self.shotButton,
                            @"toggleButton": self.toggleButton,
                            @"gridView": self.gridView,
                            };

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[closeButton(40)]-(>=0@500)-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[closeButton(40)]-(>=0@500)-|" options:0 metrics:nil views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[captureView]-0-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-120-[captureView]-(>=0@500)-|" options:0 metrics:nil views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=20@500)-[gridButton(40)]-60-[toggleButton(40)]-60-[flashButton(40)]-(>=20@500)-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=20@500)-[shotButton(80)]-(>=20@500)-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0@500)-[toggleButton(40)]-30-[shotButton(80)]-10-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0@500)-[gridButton(40)]-120-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0@500)-[flashButton(40)]-120-|" options:0 metrics:nil views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[albumButton(40)]-(>=0@500)-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0@500)-[albumButton(40)]-30-|" options:0 metrics:nil views:views]];

    [self.captureView addConstraint:[NSLayoutConstraint constraintWithItem:self.captureView
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.captureView
                                                                 attribute:NSLayoutAttributeWidth
                                                                multiplier:1.0f
                                                                  constant:0.0f]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.toggleButton
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.shotButton
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];

    [self.captureView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[gridView]-0-|" options:0 metrics:nil views:views]];
    [self.captureView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[gridView]-0-|" options:0 metrics:nil views:views]];

    [self deviceOrientationDidChange];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];

    [self.camera startRunning];
}

- (void)showControls
{
    self.gridButton.enabled = YES;
    self.toggleButton.enabled = YES;
    self.shotButton.enabled = YES;
    self.albumButton.enabled = YES;
    self.flashButton.enabled = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.hidden = YES;
    [self.camera startRunning];
    [self showControls];

    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if (status != ALAuthorizationStatusDenied)
    {
        TGAssetsLibrary *library = [TGAssetsLibrary defaultAssetsLibrary];

        __weak typeof(self) weakSelf = self;
        [library latestPhotoWithCompletion:^(UIImage *photo) {
            weakSelf.albumButton.disableTint = YES;
            [weakSelf.albumButton setImage:photo forState:UIControlStateNormal];
        }];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.camera insertSublayerWithCaptureView:self.captureView atRootView:self.view];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;

    [_camera stopRunning];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.captureView = nil;
    self.gridButton = nil;
    self.toggleButton = nil;
    self.shotButton = nil;
    self.albumButton = nil;
    self.flashButton = nil;
    self.camera = nil;
}

- (TGCamera *)camera
{
    if (!_camera)
    {
        _camera = [TGCamera cameraWithFlashButton:self.flashButton];
        self.currentScale = 1.0f;
        self.lastScale = 1.0f;
        self.maxScale = [_camera videoMaxZoomFactor];
    }
    return _camera;
}

- (UIColor *)toggleOnColor
{
    if (!_toggleOnColor)
    {
        _toggleOnColor = [TGCameraColor tintColor];
    }
    return _toggleOnColor;
}

- (UIColor *)toggleOffColor
{
    if (!_toggleOffColor)
    {
        _toggleOffColor = JoyyGray;
    }
    return _toggleOffColor;
}

- (UIView *)captureView
{
    if (!_captureView)
    {
        _captureView = [UIView new];
        _captureView.translatesAutoresizingMaskIntoConstraints = NO;
        _captureView.backgroundColor = ClearColor;

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_didTapCaptureView:)];
        tap.numberOfTapsRequired = 1;
        [_captureView addGestureRecognizer:tap];

        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(_didPinchCaptureView:)];
        [_captureView addGestureRecognizer:pinch];
    }
    return _captureView;
}

- (TGCameraGridView *)gridView
{
    if (!_gridView)
    {
        _gridView = [TGCameraGridView new];
        _gridView.translatesAutoresizingMaskIntoConstraints = NO;
        _gridView.backgroundColor = ClearColor;
        _gridView.numberOfColumns = 2;
        _gridView.numberOfRows = 2;
        _gridView.alpha = 0;
    }

    return _gridView;
}

- (TGTintedButton *)albumButton
{
    if (!_albumButton)
    {
        TGTintedButton *button = [TGTintedButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.layer.cornerRadius = 10.0f;
        button.layer.masksToBounds = YES;
        [button setImage:[UIImage imageNamed:@"CameraAlbum"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(_albumTapped) forControlEvents:UIControlEventTouchUpInside];
        _albumButton = button;
    }
    return _albumButton;
}

- (JYButton *)closeButton
{
    if (!_closeButton)
    {
        JYButton *button = [JYButton buttonWithFrame:CGRectZero buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.contentColor = self.toggleOffColor;
        button.contentAnimateToColor = self.toggleOnColor;
        button.contentEdgeInsets = UIEdgeInsetsMake(9, 9, 9, 9);
        button.foregroundColor = ClearColor;
        button.imageView.image = [UIImage imageNamed:@"close"];
        [button addTarget:self action:@selector(_closeTapped) forControlEvents:UIControlEventTouchUpInside];
        _closeButton = button;
    }
    return _closeButton;
}

- (JYButton *)flashButton
{
    if (!_flashButton)
    {
        JYButton *button = [JYButton buttonWithFrame:CGRectZero buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.foregroundColor = ClearColor;
        [button addTarget:self action:@selector(_flashTapped) forControlEvents:UIControlEventTouchUpInside];
        _flashButton = button;
    }
    return _flashButton;
}

- (JYButton *)gridButton
{
    if (!_gridButton)
    {
        JYButton *button = [JYButton buttonWithFrame:CGRectZero buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.contentColor = self.toggleOffColor;
        button.contentEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7);
        button.foregroundColor = ClearColor;
        button.imageView.image = [UIImage imageNamed:@"CameraGrid"];
        [button addTarget:self action:@selector(_gridTapped) forControlEvents:UIControlEventTouchUpInside];
        _gridButton = button;
    }
    return _gridButton;
}

- (JYButton *)shotButton
{
    if (!_shotButton)
    {
        JYButton *button = [JYButton buttonWithFrame:CGRectZero buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.foregroundColor = ClearColor;
        button.imageView.image = [UIImage imageNamed:@"CameraShot"];
        button.contentColor = self.toggleOnColor;
        [button addTarget:self action:@selector(_shotTapped) forControlEvents:UIControlEventTouchUpInside];
        _shotButton = button;
    }
    return _shotButton;
}

- (JYButton *)toggleButton
{
    if (!_toggleButton)
    {
        JYButton *button = [JYButton buttonWithFrame:CGRectZero buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.contentColor = self.toggleOffColor;
        button.contentEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7);
        button.foregroundColor = ClearColor;
        button.imageView.image = [UIImage imageNamed:@"CameraToggle"];
        [button addTarget:self action:@selector(_toggleTapped) forControlEvents:UIControlEventTouchUpInside];
        _toggleButton = button;
    }
    return _toggleButton;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *photo = [TGAlbum imageWithMediaInfo:info];

    [self _commitPhoto:photo fromAlbum:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Methods

- (void)_commitPhoto:(UIImage *)photo fromAlbum:(BOOL)fromAlbum
{
    if (self.captionViewController)
    {
        self.captionViewController.photo = photo;
        self.captionViewController.isFromAlbum = fromAlbum;
        UIViewController *vc = (UIViewController *)self.captionViewController;

        [self.navigationController pushViewController:vc animated:NO];
        return;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraDidTakePhoto:fromAlbum:withCaption:)])
    {
        [self.delegate cameraDidTakePhoto:photo fromAlbum:fromAlbum withCaption:nil];
    }
}

#pragma mark - Actions

- (void)_closeTapped
{
    if ([self.delegate respondsToSelector:@selector(cameraDidCancel)])
    {
        [self.delegate cameraDidCancel];
    }
}

- (void)_gridTapped
{
    BOOL isOff = [self.gridButton.contentColor isEqual:self.toggleOffColor];
    self.gridButton.contentColor = isOff ? self.toggleOnColor: self.toggleOffColor;

    CGFloat newAlpha = ([self.gridView alpha] == 0.) ? 1. : 0.;

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.gridView.alpha = newAlpha;
    } completion:NULL];
}

- (void)_flashTapped
{
    [self.camera changeFlashModeWithButton:self.flashButton];
}

- (void)_shotTapped
{
    self.shotButton.enabled = NO;
    self.albumButton.enabled = NO;
    
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation videoOrientation = [self videoOrientationForDeviceOrientation:deviceOrientation];

    __weak typeof(self) weakSelf = self;
    [_camera takePhotoWithCaptureView:self.captureView videoOrientation:videoOrientation cropSize:self.captureView.frame.size
         completion:^(UIImage *photo) {
             [weakSelf _commitPhoto:photo fromAlbum:NO];
    }];
}

- (void)_albumTapped
{
    self.shotButton.enabled = NO;
    self.albumButton.enabled = NO;

    UIImagePickerController *pickerController = [TGAlbum imagePickerControllerWithDelegate:self];
    [self presentViewController:pickerController animated:YES completion:nil];
}

- (void)_toggleTapped
{
    BOOL isOff = [self.toggleButton.contentColor isEqual:self.toggleOffColor];
    self.toggleButton.contentColor = isOff ? self.toggleOnColor: self.toggleOffColor;

    [self.camera toogleWithFlashButton:self.flashButton];

    self.maxScale = [_camera videoMaxZoomFactor];
    self.currentScale = 1.0f;
    self.lastScale = 1.0f;
}

- (void)_didTapCaptureView:(UITapGestureRecognizer *)recognizer
{
    CGPoint touchPoint = [recognizer locationInView:self.captureView];
    [self.camera captureView:self.captureView focusAtTouchPoint:touchPoint];
}

- (void)_didPinchCaptureView:(UIPinchGestureRecognizer *)recognizer
{
    CGFloat newScale = recognizer.scale * self.currentScale;

    if (newScale > self.maxScale)
    {
        newScale = self.maxScale;
    }

    if (newScale < 1.f) {
        newScale = 1.f;
    }

    if ([self.camera zoomToScale:newScale])
    {
        self.lastScale = newScale;
    }

    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        self.currentScale = self.lastScale;
    }
}

#pragma mark -
#pragma mark - Private methods

- (void)deviceOrientationDidChange
{
    UIDeviceOrientation orientation = [UIDevice.currentDevice orientation];
    NSInteger degress;
    
    switch (orientation) {
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationUnknown:
            degress = 0;
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            degress = 90;
            break;
            
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationPortraitUpsideDown:
            degress = 180;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            degress = 270;
            break;
    }
    
    CGFloat radians = degress * M_PI / 180;
    CGAffineTransform transform = CGAffineTransformMakeRotation(radians);
    
    [UIView animateWithDuration:0.05f animations:^{
        self.gridButton.transform =
        self.toggleButton.transform =
        self.albumButton.transform =
        self.flashButton.transform = transform;
    }];
}

- (AVCaptureVideoOrientation)videoOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation) deviceOrientation;
    
    switch (deviceOrientation) {
        case UIDeviceOrientationLandscapeLeft:
            result = AVCaptureVideoOrientationLandscapeRight;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            result = AVCaptureVideoOrientationLandscapeLeft;
            break;
            
        default:
            break;
    }
    
    return result;
}

@end
