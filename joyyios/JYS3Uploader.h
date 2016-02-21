//
//  JYS3Uploader.h
//  joyyios
//
//  Created by Ping Yang on 2/20/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

typedef void(^S3ResourceHandler)(NSString *url);

@interface JYS3Uploader : NSObject

- (void)uploadAudioFile:(NSURL *)fileURL success:(S3ResourceHandler)success failure:(FailureHandler)failure;
- (void)uploadImage:(UIImage *)image success:(S3ResourceHandler)success failure:(FailureHandler)failure;

@end
