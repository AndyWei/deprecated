//
//  NSURL+Joyy.h
//  joyyios
//
//  Created by Ping Yang on 2/20/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

@interface NSURL (Joyy)

+ (NSURL *)uniqueTemporaryFileURL;
+ (NSURL *)temporaryFileURLWithFilename:(NSString *)filename;

@end
