//
//  JYS3Uploader.m
//  joyyios
//
//  Created by Ping Yang on 2/20/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <AWSS3/AWSS3.h>

#import "JYFilename.h"
#import "JYS3Uploader.h"

@implementation JYS3Uploader

- (void)uploadImage:(UIImage *)image success:(S3ResourceHandler)success failure:(FailureHandler)failure
{
    NSURL *fileURL = [NSURL uniqueTemporaryFileURL];

    NSData *imageData = UIImageJPEGRepresentation(image, kPhotoQuality);
    [imageData writeToURL:fileURL atomically:YES];

    NSString *filename = [[JYFilename sharedInstance] randomFilenameWithHttpContentType:kContentTypeJPG];

    [self uploadLocalFile:fileURL
                 withName:filename
                     type:kContentTypeJPG
                 toBucket:[JYFilename sharedInstance].messageBucketName
                  success:success
                  failure:failure];
}

- (void)uploadAudioFile:(NSURL *)fileURL success:(S3ResourceHandler)success failure:(FailureHandler)failure
{
    NSString *filename = [[JYFilename sharedInstance] randomFilenameWithHttpContentType:kContentTypeAudioMPEG];
    [self uploadLocalFile:fileURL
                 withName:filename
                     type:kContentTypeAudioMPEG
                 toBucket:[JYFilename sharedInstance].messageBucketName
                  success:success
                  failure:failure];
}

- (void)uploadLocalFile:(NSURL *)fileURL
               withName:(NSString *)filename
                   type:(NSString *)type
               toBucket:(NSString *)bucket
                success:(S3ResourceHandler)success
                failure:(FailureHandler)failure
{
    NSString *s3region = [JYFilename sharedInstance].region;
    NSString *s3url = [NSString stringWithFormat:@"%@:%@", s3region, filename];

    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    if (!transferManager)
    {
        NSLog(@"Error: no S3 transferManager");
        if (failure)
        {
            NSError *error = [NSError errorWithDomain:@"winkrock" code:2000 userInfo:@{@"error": @"no S3 transferManager"}];
            dispatch_async(dispatch_get_main_queue(), ^(void){ failure(error); });
        }
        return;
    }

    AWSS3TransferManagerUploadRequest *request = [AWSS3TransferManagerUploadRequest new];
    request.bucket = bucket;
    request.key = filename;
    request.body = fileURL;
    request.contentType = type;

    [[transferManager upload:request] continueWithBlock:^id(AWSTask *task) {
        if (task.error)
        {
            NSLog(@"Error: AWSS3TransferManager upload error = %@", task.error);

            if (failure)
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){ failure(task.error); });
            }
        }
        if (task.result)
        {
            AWSS3TransferManagerUploadOutput *uploadOutput = task.result;
            NSLog(@"Success: AWSS3TransferManager upload task.result = %@", uploadOutput);

            if (success)
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){ success(s3url); });
            }
        }
        return nil;
    }];
}

@end
