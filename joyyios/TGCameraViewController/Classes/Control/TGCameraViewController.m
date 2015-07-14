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

#import "JYPhotoCaptionViewController.h"
#import "TGCameraColor.h"
#import "TGCameraViewController.h"
#import "TGCameraSlideView.h"
#import "TGTintedButton.h"


@interface TGCameraViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic) UIColor *toggleOnColor;
@property (nonatomic) UIColor *toggleOffColor;

@property (strong, nonatomic) IBOutlet UIView *captureView;
@property (strong, nonatomic) IBOutlet UIView *separatorView;
@property (strong, nonatomic) IBOutlet UIView *actionsView;
@property (strong, nonatomic) IBOutlet TGTintedButton *gridButton;
@property (strong, nonatomic) IBOutlet TGTintedButton *toggleButton;
@property (strong, nonatomic) IBOutlet UIButton *shotButton;
@property (strong, nonatomic) IBOutlet TGTintedButton *albumButton;
@property (strong, nonatomic) IBOutlet UIButton *flashButton;
@property (strong, nonatomic) IBOutlet TGCameraSlideView *slideUpView;
@property (strong, nonatomic) IBOutlet TGCameraSlideView *slideDownView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toggleButtonWidth;

@property (strong, nonatomic) TGCamera *camera;
@property (nonatomic) BOOL wasLoaded;

- (IBAction)closeTapped;
- (IBAction)gridTapped;
- (IBAction)flashTapped;
- (IBAction)shotTapped;
- (IBAction)albumTapped;
- (IBAction)toggleTapped;
- (IBAction)handleTapGesture:(UITapGestureRecognizer *)recognizer;

- (void)deviceOrientationDidChangeNotification;
- (void)latestPhoto;
- (AVCaptureVideoOrientation)videoOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation;
- (void)viewWillDisappearWithCompletion:(void (^)(void))completion;

@end



@implementation TGCameraViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self deviceOrientationDidChangeNotification];

    _camera = [TGCamera cameraWithFlashButton:_flashButton];

    if (CGRectGetHeight([[UIScreen mainScreen] bounds]) <= 480) {
        _topViewHeight.constant = 0;
    }
    
    if ([[TGCamera getOption:kTGCameraOptionHiddenToggleButton] boolValue] == YES) {
        _toggleButton.hidden = YES;
        _toggleButtonWidth.constant = 0;
    }
    
    if ([[TGCamera getOption:kTGCameraOptionHiddenAlbumButton] boolValue] == YES) {
        _albumButton.hidden = YES;
    }

    [self createTitleLabel];
    [_albumButton.layer setCornerRadius:10.f];
    [_albumButton.layer setMasksToBounds:YES];

    _captureView.backgroundColor = [UIColor clearColor];
    _separatorView.hidden = YES;

    _toggleOnColor = [TGCameraColor tintColor];
    _toggleOffColor = [UIColor grayColor];
    _gridButton.customTintColorOverride = _toggleButton.customTintColorOverride = _toggleOffColor;
}

- (void)createTitleLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, SCREEN_WIDTH, 44)];
    label.text = self.title;
    self.title = nil;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = JoyyGray;
    label.font = [UIFont boldSystemFontOfSize:17];

    [self.view addSubview:label];
}

- (void)showControls:(BOOL)show
{
    _actionsView.hidden = !show;

    _gridButton.enabled =
    _toggleButton.enabled =
    _shotButton.enabled =
    _albumButton.enabled =
    _flashButton.enabled = show;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChangeNotification)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];

    [_camera startRunning];
    [self showControls:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (_wasLoaded == NO) {
        _wasLoaded = YES;
        [_camera insertSublayerWithCaptureView:_captureView atRootView:self.view];
    }
    
    // get the latest image from the album
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if (status != ALAuthorizationStatusDenied) {
        // access to album is authorised
        [self latestPhoto];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
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
    _captureView = nil;
    _separatorView = nil;
    _actionsView = nil;
    _gridButton = nil;
    _toggleButton = nil;
    _shotButton = nil;
    _albumButton = nil;
    _flashButton = nil;
    _slideUpView = nil;
    _slideDownView = nil;
    _camera = nil;
}

#pragma mark -
#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *photo = [TGAlbum imageWithMediaInfo:info];
    
    JYPhotoCaptionViewController *viewController = [JYPhotoCaptionViewController newWithDelegate:_delegate photo:photo];
    viewController.albumPhoto = YES;
    [self.navigationController pushViewController:viewController animated:NO];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark - Actions

- (IBAction)closeTapped
{
    if ([_delegate respondsToSelector:@selector(cameraDidCancel)]) {
        [_delegate cameraDidCancel];
    }
}

- (IBAction)gridTapped
{
    BOOL isOff = [_gridButton.customTintColorOverride isEqual:_toggleOffColor];
    _gridButton.customTintColorOverride = isOff ? _toggleOnColor: _toggleOffColor;
    [_camera changeGridView];
}

- (IBAction)flashTapped
{
    [_camera changeFlashModeWithButton:_flashButton];
}

- (IBAction)shotTapped
{
    _shotButton.enabled =
    _albumButton.enabled = NO;
    
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation videoOrientation = [self videoOrientationForDeviceOrientation:deviceOrientation];

    __weak typeof(self) weakSelf = self;
    [_camera takePhotoWithCaptureView:_captureView videoOrientation:videoOrientation cropSize:_captureView.frame.size
         completion:^(UIImage *photo) {
             UIViewController *viewController = [JYPhotoCaptionViewController newWithDelegate:_delegate photo:photo];
             [weakSelf.navigationController pushViewController:viewController animated:NO];
    }];
}

- (IBAction)albumTapped
{
    _shotButton.enabled =
    _albumButton.enabled = NO;

    __weak typeof(self) weakSelf = self;
    [self viewWillDisappearWithCompletion:^{
        UIImagePickerController *pickerController = [TGAlbum imagePickerControllerWithDelegate:self];
        [weakSelf presentViewController:pickerController animated:YES completion:nil];
    }];
}

- (IBAction)toggleTapped
{
    BOOL isOff = [_toggleButton.customTintColorOverride isEqual:_toggleOffColor];
    _toggleButton.customTintColorOverride = isOff ? _toggleOnColor: _toggleOffColor;

    [_camera toogleWithFlashButton:_flashButton];
}

- (IBAction)handleTapGesture:(UITapGestureRecognizer *)recognizer
{
    CGPoint touchPoint = [recognizer locationInView:_captureView];
    [_camera focusView:_captureView inTouchPoint:touchPoint];
}

#pragma mark -
#pragma mark - Private methods

- (void)deviceOrientationDidChangeNotification
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
    
    [UIView animateWithDuration:.5f animations:^{
        _gridButton.transform =
        _toggleButton.transform =
        _albumButton.transform =
        _flashButton.transform = transform;
    }];
}

-(void)latestPhoto
{
    TGAssetsLibrary *library = [TGAssetsLibrary defaultAssetsLibrary];
    
    __weak __typeof(self) weakSelf = self;
    [library latestPhotoWithCompletion:^(UIImage *photo) {
        weakSelf.albumButton.disableTint = YES;
        [weakSelf.albumButton setImage:photo forState:UIControlStateNormal];
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

- (void)viewWillDisappearWithCompletion:(void (^)(void))completion
{
    _actionsView.hidden = YES;
    
    [TGCameraSlideView showSlideUpView:_slideUpView slideDownView:_slideDownView atView:_captureView completion:^{
        completion();
    }];
}

@end
