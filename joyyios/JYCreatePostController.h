//
//  JYCreatePostController.h
//  joyyios
//
//  Created by Ping Yang on 12/13/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@class JYPost;

typedef void(^PostHandler)(JYPost *);


@interface JYCreatePostController : NSObject

- (void)createPostWithMedia:(id)media caption:(NSString *)caption success:(PostHandler)success failure:(FailureHandler)failure;

@end
