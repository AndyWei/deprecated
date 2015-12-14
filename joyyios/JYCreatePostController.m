//
//  JYCreatePostController.m
//  joyyios
//
//  Created by Ping Yang on 12/13/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <AWSS3/AWSS3.h>

#import "JYCreatePostController.h"
#import "JYFilename.h"
#import "JYPost.h"

@implementation JYCreatePostController

#pragma mark - AWS S3

- (void)createPostWithMedia:(id)media caption:(NSString *)caption success:(PostHandler)success failure:(FailureHandler)failure
{
    if ([media isKindOfClass:UIImage.class])
    {
        UIImage *image = (UIImage *)media;
        [self _createPostWithImage:image caption:caption success:success failure:failure];
    }
}

- (void)_createPostWithImage:(UIImage *)image caption:(NSString *)caption success:(PostHandler)success failure:(FailureHandler)failure
{
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"timeline"]];

    NSData *imageData = UIImageJPEGRepresentation(image, kPhotoQuality);
    [imageData writeToURL:fileURL atomically:YES];

    NSString *s3filename = [[JYFilename sharedInstance] randomFilenameWithHttpContentType:kContentTypeJPG];
    NSString *s3region = [JYFilename sharedInstance].region;
    NSString *s3url = [NSString stringWithFormat:@"%@:%@", s3region, s3filename];

    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    if (!transferManager)
    {
        NSLog(@"Error: no S3 transferManager");
        if (failure)
        {
            NSError *error = [NSError errorWithDomain:@"winkrock" code:2000 userInfo:@{@"error": @"no S3 transferManager"}];
            failure(error);
        }
        return;
    }

    AWSS3TransferManagerUploadRequest *request = [AWSS3TransferManagerUploadRequest new];
    request.bucket = [JYFilename sharedInstance].postBucketName;
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
                // Unknown error.
                NSLog(@"Error: AWSS3TransferManager upload error = %@", task.error);
            }
            if (failure)
            {
                failure(task.error);
            }
        }
        if (task.result)
        {
            AWSS3TransferManagerUploadOutput *uploadOutput = task.result;
            NSLog(@"Success: AWSS3TransferManager upload task.result = %@", uploadOutput);
            [weakSelf _createRecordWithURL:s3url caption:caption success:success failure:failure];
        }
        return nil;
    }];
}

#pragma mark - Network

- (void)_createRecordWithURL:(NSString *)s3url caption:(NSString *)caption success:(PostHandler)success failure:(FailureHandler)failure
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"post/create"];
    NSMutableDictionary *parameters = [self _parametersWithURL:s3url caption:caption];

    [manager POST:url
       parameters:parameters
          success:^(NSURLSessionTask *operation, id responseObject) {

              NSLog(@"Success: post/create response = %@", responseObject);
              NSError *error = nil;
              JYPost *post = (JYPost *)[MTLJSONAdapter modelOfClass:JYPost.class fromJSONDictionary:responseObject error:&error];
              if (success)
              {
                  success(post);
              }

          } failure:^(NSURLSessionTask *operation, NSError *error) {
              NSLog(@"Failure: post/create error = %@", error);
              if (failure)
              {
                  failure(error);
              }
          }];
}

- (NSMutableDictionary *)_parametersWithURL:(NSString *)url caption:(NSString *)caption
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    [parameters setObject:url forKey:@"url"];
    if (caption)
    {
        [parameters setObject:caption forKey:@"caption"];
    }

    return parameters;
}

@end
