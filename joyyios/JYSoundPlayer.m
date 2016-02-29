//
//  JYSoundPlayer.m
//  joyyios
//
//  Created by Ping Yang on 8/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "JYSoundPlayer.h"

@interface JYSoundPlayer ()
@property (nonatomic) AVAudioPlayer *player;
@end

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

- (void)playVibrate
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)playMessageReceivedAlertWithVibrate:(BOOL)vibrate
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

- (void)playStartWithVibrate:(BOOL)vibrate
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"beep_short_on" withExtension:@"wav"];
    [self playFile:url withVibrate:vibrate];
}

- (void)playFinishWithVibrate:(BOOL)vibrate
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"beep_short_off" withExtension:@"wav"];
    [self playFile:url withVibrate:vibrate];
}

- (void)playCancelWithVibrate:(BOOL)vibrate
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"cancel" withExtension:@"wav"];
    [self playFile:url withVibrate:vibrate];
}

- (void)playFile:(NSURL *)fileURL withVibrate:(BOOL)vibrate
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    [audioSession setCategory: AVAudioSessionCategoryPlayback error:&error];

    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    self.player.volume = 2.0;
    [self.player play];

    if (vibrate)
    {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

@end
