//
//  JYSoundPlayer.m
//  joyyios
//
//  Created by Ping Yang on 8/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//


#import <AudioToolbox/AudioToolbox.h>

#import "JYSoundPlayer.h"

@implementation JYSoundPlayer

+ (void)playMessageReceivedAlertWithVibrate:(BOOL)vibrate
{
    NSURL *fileURL = [NSURL URLWithString:@"/System/Library/Audio/UISounds/Modern/sms_alert_bamboo.caf"]; // see list below
    SystemSoundID soundID = 0;
    AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)fileURL, &soundID);

    NSLog(@"soundID: %d", soundID);
    if (soundID == 0) {
        soundID = 1003; // use SMSReceived sound as default
    }
    AudioServicesPlaySystemSound(soundID);
    if (vibrate)
    {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

@end
