//
//  JYDeviceManager.h
//  joyyios
//
//  Created by Ping Yang on 11/4/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@interface JYDeviceManager : NSObject

- (void)start;
- (void)updateDeviceBadgeCount:(NSInteger)count;

@property (nonatomic) NSString *deviceToken;

@end
