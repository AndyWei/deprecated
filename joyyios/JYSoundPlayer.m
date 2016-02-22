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

+ (JYSoundPlayer *)sharedInstance
{
    static JYSoundPlayer *_sharedInstance = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedInstance = [JYSoundPlayer new];
    });

    return _sharedInstance;
}

+ (void)playVibrate
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

+ (void)playMessageReceivedAlertWithVibrate:(BOOL)vibrate
{
    NSURL *fileURL = [NSURL URLWithString:@"/System/Library/Audio/UISounds/Tink.caf"];
    SystemSoundID soundID = 0;
    AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)fileURL, &soundID);

    if (soundID == 0)
    {
        soundID = 1003; // use SMSReceived sound as default
    }
    AudioServicesPlaySystemSound(soundID);

    if (vibrate)
    {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

+ (void)playAudioRecordingStartedAlert
{
    NSURL *fileURL = [NSURL URLWithString:@"/System/Library/Audio/UISounds/SIMToolkitGeneralBeep.caf"];
    SystemSoundID soundID = 0;
    AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)fileURL, &soundID);

    if (soundID == 0)
    {
        soundID = 1113; // use BeginRecording sound as default
    }
    AudioServicesPlaySystemSound(soundID); // SIMToolkitGeneralBeep
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

+ (void)playAudioRecordingCanceledAlert
{
    NSURL *fileURL = [NSURL URLWithString:@"/System/Library/Audio/UISounds/SIMToolkitNegativeACK.caf"];
    SystemSoundID soundID = 0;
    AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)fileURL, &soundID);

    if (soundID == 0)
    {
        soundID = 1114; // use EndRecording sound as default
    }
    AudioServicesPlaySystemSound(soundID); // SIMToolkitNegativeACK
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

@end
