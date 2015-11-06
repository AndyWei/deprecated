//
//  JYAmazonClientManager.h
//  joyyios
//
//  Created by Ping Yang on 9/1/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AWSCore/AWSCore.h>

@interface JYAmazonClientManager: NSObject

+ (JYAmazonClientManager *)sharedInstance;

- (void)start;

@end

