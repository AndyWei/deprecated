//
//  JYSoundPlayer.h
//  joyyios
//
//  Created by Ping Yang on 8/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@interface JYSoundPlayer : NSObject

+ (JYSoundPlayer *)sharedInstance;
- (void)playVibrate;
- (void)playMessageReceivedAlertWithVibrate:(BOOL)vibrate;
- (void)playStartWithVibrate:(BOOL)vibrate;
- (void)playCancelWithVibrate:(BOOL)vibrate;

@end
