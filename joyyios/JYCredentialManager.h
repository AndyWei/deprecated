//
//  JYCredentialManager.h
//  joyyios
//
//  Created by Ping Yang on 11/4/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@interface JYCredentialManager : NSObject

+ (JYCredentialManager *)sharedInstance;
- (void)start;

@end
