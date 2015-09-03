//
//  JYFile.h
//  joyyios
//
//  Created by Ping Yang on 9/2/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@interface JYFile : NSObject

+ (NSString *)filenameWithHttpContentType:(NSString *)contentType;
+ (NSString *)filenameWithSuffix:(NSString *)suffix;
+ (NSString *)timeInMiliSeconds;

@end
