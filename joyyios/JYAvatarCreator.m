//
//  JYAvatarCreator.m
//  joyyios
//
//  Created by Ping Yang on 12/28/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AWSS3/AWSS3.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYAvatarCreator.h"
#import "JYFilename.h"
#import "JYYRS.h"
#import "NSString+Joyy.h"
#import "TGCameraColor.h"
#import "TGCameraViewController.h"

@interface JYAvatarCreator () <TGCameraDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, weak) UIViewController *viewController;
@end


@implementation JYAvatarCreator

- (instancetype)initWithViewController:(UIViewController *)viewController
{
    if (self = [super init])
    {
        self.viewController = viewController;
    }
    return self;
}

- (void)showOptions
{
    NSString *title  = NSLocalizedString(@"Where to fetch your primary photo?", nil);
    NSString *cancel = NSLocalizedString(@"Cancel", nil);
    NSString *camera = NSLocalizedString(@"Camera", nil);
    NSString *photoLibary = NSLocalizedString(@"Photo Libary", nil);

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:photoLibary style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [weakSelf showImagePicker];
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:camera style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [weakSelf showCamera];
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:nil]];

    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)showImagePicker
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];

    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *) kUTTypeImage];

    picker.allowsEditing = YES;
    picker.delegate = self;

    [self.viewController.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)showCamera
{
    [TGCameraColor setTintColor:JoyyBlue];
    TGCameraNavigationController *camera = [TGCameraNavigationController cameraWithDelegate:self];
    camera.title = NSLocalizedString(@"Primary Photo", nil);

    [self.viewController presentViewController:camera animated:YES completion:nil];
}

- (void)_handleImage:(UIImage *)image
{
    if (self.delegate)
    {
        [self.delegate creator:self didTakePhoto:image];
    }
}

#pragma mark - TGCameraDelegate Methods

- (void)cameraDidTakePhoto:(UIImage *)image fromAlbum:(BOOL)fromAlbum withCaption:(NSString *)caption
{
    [self.viewController dismissViewControllerAnimated:YES completion:nil];

    UIImage *scaledImage = [image imageScaledToSize:CGSizeMake(kPhotoWidth, kPhotoWidth)];
    [self _handleImage:scaledImage];
}

- (void)cameraDidCancel
{
    [self.viewController dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];

    UIImage *editedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    UIImage *scaledImage = [editedImage imageScaledToSize:CGSizeMake(kPhotoWidth, kPhotoWidth)];
    [self _handleImage:scaledImage];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Indicators

- (void)_showNetworkIndicator:(BOOL)show
{
    if (show)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [KVNProgress show];
    }
    else
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [KVNProgress dismiss];
    }
}

#pragma mark - AWS S3

- (void)uploadAvatarImage:(UIImage *)image success:(Action)success failure:(FailureHandler)failure
{
    [self _showNetworkIndicator:YES];

    NSData *imageData = UIImageJPEGRepresentation(image, kPhotoQuality);
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"profile"]];
    [imageData writeToURL:fileURL atomically:YES];

    JYFriend *me = [JYFriend myself];
    NSString *s3filename = [me nextAvatarFilename];

    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    if (!transferManager)
    {
        NSLog(@"Error: no S3 transferManager");
        return;
    }

    AWSS3TransferManagerUploadRequest *request = [AWSS3TransferManagerUploadRequest new];
    request.bucket = [JYFilename sharedInstance].avatarBucketName;
    request.key = s3filename;
    request.body = fileURL;
    request.contentType = kContentTypeJPG;

    __weak typeof(self) weakSelf = self;
    [[transferManager upload:request] continueWithBlock:^id(AWSTask *task) {

        if (task.error)
        {
            if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain])
            {
                switch (task.error.code)
                {
                    case AWSS3TransferManagerErrorCancelled:
                    case AWSS3TransferManagerErrorPaused:
                        break;
                    default:
                        NSLog(@"Error: AWSS3TransferManager upload error = %@", task.error);
                        break;
                }
            }
            else
            {
                NSLog(@"Error: AWSS3TransferManager upload error = %@", task.error);
            }

            NSString *errorMessage = NSLocalizedString(@"Upload photo failed", nil);

            [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                           message:errorMessage
                   backgroundColor:FlatYellow
                         textColor:FlatBlack
                              time:5];
            
            if (failure)
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    failure(task.error);
                });
            }

            [weakSelf _showNetworkIndicator:NO];

            return nil;
        }

        if (task.result)
        {
            AWSS3TransferManagerUploadOutput *uploadOutput = task.result;
            NSLog(@"Success: AWSS3TransferManager upload task.result = %@", uploadOutput);

            [weakSelf _updateLocalYRS];
            if (success)
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    success();
                });
            }
        }
        [weakSelf _showNetworkIndicator:NO];
        return nil;
    }];
}

- (void)_updateLocalYRS
{
    JYYRS *yrs = [JYYRS yrsWithValue:[JYCredential current].yrsValue];
    yrs.version = [yrs nextVersion];
    [JYFriend myself].yrsValue = yrs.value;

    // write JYCredential ask for keychain access, which must be executed in main thread to avoid OSStatus error: [-34018]
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [JYCredential current].yrsValue = yrs.value;
    });
}

- (void)writeRemoteProfileWithParameters:(NSDictionary *)parameters success:(Action)success failure:(FailureHandler)failure
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"user/profile"];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [manager POST:url
       parameters:parameters
          success:^(NSURLSessionTask *operation, id responseObject) {
              NSLog(@"Success: POST user/profile");

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

              if (success)
              {
                  dispatch_async(dispatch_get_main_queue(), ^(void){
                      success();
                  });
              }
          }
          failure:^(NSURLSessionTask *operation, NSError *error) {
              NSLog(@"Error: POST user/profile error = %@", error);

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

              if (failure)
              {
                  dispatch_async(dispatch_get_main_queue(), ^(void){
                      failure(error);
                  });
              }
          }];
}

@end
