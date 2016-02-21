//
//  JYAudioRecorder.m
//  joyyios
//
//  Created by Ping Yang on 2/20/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "JYAudioRecorder.h"

@interface JYAudioRecorder () <AVAudioRecorderDelegate>
@property (nonatomic) AVAudioRecorder *recorder;
@property (nonatomic) NSDate *startTimestamp;
@property (nonatomic) NSDate *stopTimestamp;
@property (nonatomic) NSDictionary *recorderSetting;
@property (nonatomic) NSURL *outputFileURL;
@end

@implementation JYAudioRecorder

- (void)start
{
    self.outputFileURL = [NSURL uniqueTemporaryFileURL];

    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];

    // Initiate and prepare the recorder, note on every start we need a new outputFileURL to avoid conflicts
    self.recorder = [[AVAudioRecorder alloc] initWithURL:self.outputFileURL settings:self.recorderSetting error:NULL];
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
    [self.recorder record];
    self.startTimestamp = [NSDate date];
}

- (void)stop
{
    [self.recorder stop];
    self.stopTimestamp = [NSDate date];
}

- (NSDictionary *)recorderSetting
{
    if (!_recorderSetting)
    {
        _recorderSetting = @{
                             AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                             AVSampleRateKey: @(44100.0),
                             AVNumberOfChannelsKey:@(2)
                             };
    }
    return _recorderSetting;
}

#pragma mark - AVAudioRecorderDelegate Methods

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (flag && self.delegate)
    {
        NSTimeInterval duration = [self.stopTimestamp timeIntervalSinceDate:self.startTimestamp];
        [self.delegate recorder:self didRecordAudioFile:self.outputFileURL duration:duration];
    }
}

@end
