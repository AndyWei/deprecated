//
//  JYAvatarCreator.m
//  joyyios
//
//  Created by Ping Yang on 12/28/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AWSS3/AWSS3.h>
#import <KVNProgress/KVNProgress.h>

#import "JYAvatarCreator.h"
#import "JYFilename.h"
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
                                                [weakSelf _showImagePicker];
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:camera style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [weakSelf _showCamera];
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:nil]];

    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)_showImagePicker
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];

    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *) kUTTypeImage];

    picker.allowsEditing = YES;
    picker.delegate = self;

    [self.viewController.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)_showCamera
{
    [TGCameraColor setTintColor:JoyyBlue];
    TGCameraNavigationController *camera = [TGCameraNavigationController cameraWithDelegate:self];
    camera.title = NSLocalizedString(@"Primary Photo", nil);

    [self.viewController presentViewController:camera animated:NO completion:nil];
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

    NSString *idString = [NSString stringWithFormat:@"%llu", [[JYCredential current].userId unsignedLongLongValue]];
    NSString *filename = [idString reversedString]; // use reversed userid as filename to avoid hash conflict in S3
    NSString *s3filename = [filename stringByAppendingString:@".jpg"];

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
        [weakSelf _showNetworkIndicator:NO];

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
            if (failure)
            {
                failure(task.error);
            }
            return nil;
        }

        if (task.result)
        {
            AWSS3TransferManagerUploadOutput *uploadOutput = task.result;
            NSLog(@"Success: AWSS3TransferManager upload task.result = %@", uploadOutput);

            if (success)
            {
                success();
            }
        }
        return nil;
    }];
}

@end
