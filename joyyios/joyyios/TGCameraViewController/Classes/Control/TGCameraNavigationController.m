//
//  TGCameraNavigationController.m
//  TGCameraViewController
//
//  Created by Bruno Tortato Furtado on 20/09/14.
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

@import AVFoundation;
#import "TGCameraAuthorizationViewController.h"
#import "TGCameraNavigationController.h"
#import "TGCameraViewController.h"

@interface TGCameraNavigationController ()
@end



@implementation TGCameraNavigationController

+ (instancetype)cameraWithDelegate:(id<TGCameraDelegate>)delegate
{
    return [TGCameraNavigationController cameraWithDelegate:delegate captionViewController:nil];
}

+ (instancetype)cameraWithDelegate:(id<TGCameraDelegate>)delegate captionViewController:(id<TGCaptionViewControllerInterface>)vc
{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    TGCameraNavigationController *navigationController = [super new];

    if (navigationController) {

        switch (status) {
            case AVAuthorizationStatusAuthorized:
                [navigationController setupAuthorizedWithDelegate:delegate captionViewController:vc];
                break;
                
            case AVAuthorizationStatusRestricted:
            case AVAuthorizationStatusDenied:
                [navigationController setupDenied];
                break;
                
            case AVAuthorizationStatusNotDetermined:
                [navigationController setupNotDeterminedWithDelegate:delegate captionViewController:vc];
                break;
        }
    }

    navigationController.navigationBarHidden = NO;
    navigationController.navigationBar.barTintColor = JoyyBlack;
    navigationController.navigationBar.translucent = NO;
    [navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: JoyyGray}];

    return navigationController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];

    for (UIViewController *viewController in self.viewControllers)
    {
        viewController.title = self.title;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark -
#pragma mark - Private methods

- (void)setupAuthorizedWithDelegate:(id<TGCameraDelegate>)delegate captionViewController:(id<TGCaptionViewControllerInterface>)vc
{
    TGCameraViewController *camera = [TGCameraViewController new];
    camera.delegate = delegate;
    camera.captionViewController = vc;
    self.viewControllers = @[camera];
}

- (void)setupNotDeterminedWithDelegate:(id<TGCameraDelegate>)delegate captionViewController:(id<TGCaptionViewControllerInterface>)vc
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted)
        {
            [self setupAuthorizedWithDelegate:delegate captionViewController:vc];
        }
        else
        {
            [self setupDenied];
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

- (void)setupDenied
{
    UIViewController *viewController = [TGCameraAuthorizationViewController new];
    self.viewControllers = @[viewController];
}

@end
