//
//  JYAudioRecorder.m
//  joyyios
//
//  Created by Ping Yang on 2/20/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MSWeakTimer/MSWeakTimer.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYAudioRecorder.h"

@interface JYAudioRecorder () <AVAudioRecorderDelegate>
@property (nonatomic) AVAudioRecorder *avRecorder;
@property (nonatomic) NSDate *startTimestamp;
@property (nonatomic) NSDate *stopTimestamp;
@property (nonatomic) NSDictionary *recorderSetting;
@property (nonatomic) NSURL *outputFileURL;

@property (nonatomic) TTTAttributedLabel *hintLabel;
@property (nonatomic) TTTAttributedLabel *durationLabel;
@property (nonatomic) UIImageView *imageView;

@property (nonatomic) MSWeakTimer *durationTimer;
@property (nonatomic) uint32_t duration;

@end

@implementation JYAudioRecorder

- (instancetype)init
{
    if (self = [super init])
    {
        self.backgroundColor = JoyyWhitePure;

        [self addSubview:self.imageView];
        [self addSubview:self.hintLabel];
        [self addSubview:self.durationLabel];

        NSDictionary *views = @{
                                @"imageView": self.imageView,
                                @"hintLabel": self.hintLabel,
                                @"durationLabel": self.durationLabel
                                };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imageView(25)]-15-[durationLabel(100)]-10-[hintLabel]-10-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0@500)-[imageView(25)]-(>=0@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0@500)-[durationLabel]-(>=0@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0@500)-[hintLabel]-(>=0@500)-|" options:0 metrics:nil views:views]];

        [self pinCenterYOfSubviews:@[self.imageView, self.hintLabel, self.durationLabel]];
    }
    return self;
}

- (UIImageView *)imageView
{
    if (!_imageView)
    {
        _imageView = [UIImageView new];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

- (TTTAttributedLabel *)durationLabel
{
    if (!_durationLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:20];
        label.backgroundColor = ClearColor;
        label.textColor = JoyyGrayDark;
        _durationLabel = label;
    }
    return _durationLabel;
}

- (TTTAttributedLabel *)hintLabel
{
    if (!_hintLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:16];
        label.backgroundColor = ClearColor;
        label.textColor = JoyyGray;
        label.textAlignment = NSTextAlignmentLeft;
        label.text = NSLocalizedString(@"slide up or left to cancel", nil);
        _hintLabel = label;
    }
    return _hintLabel;
}

- (void)start
{
    [self.avRecorder record];
    self.startTimestamp = [NSDate date];
    self.duration = 0;

    // duration label
    self.durationLabel.text = @"0:00";
    [self _startDurationTimer];
    
    // mic icon animation
    self.imageView.alpha = 1.0;
    self.imageView.image = [UIImage imageNamed:@"microphone" maskedWithColor:JoyyRedPure];
    self.imageView.backgroundColor = JoyyWhitePure;
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                     animations:^{
                         self.imageView.alpha = 0.0;
                     }
                     completion:nil];
}

- (void)stop
{
    self.stopTimestamp = [NSDate date];
    [self.avRecorder stop];
    [self _stopDurationTimer];

    [self.imageView.layer removeAllAnimations];
    self.imageView.alpha = 1.0f;
    [self _playStopAnimation];
}

- (void)cancel
{
    self.stopTimestamp = [NSDate dateWithTimeIntervalSince1970:0]; // invalid timestamp to indicate cancel
    [self.avRecorder stop];
    [self _stopDurationTimer];

    _avRecorder = nil; // force re-init recorder for next time use

    [self.imageView.layer removeAllAnimations];
    self.imageView.alpha = 1.0f;
    [self _playCancelAnimation];
}

- (AVAudioRecorder *)avRecorder
{
    if (!_avRecorder)
    {
        self.outputFileURL = [NSURL uniqueTemporaryFileURL];

        // Setup audio session
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];

        // Initiate and prepare the recorder, note on every start we need a new outputFileURL to avoid conflicts
        _avRecorder = [[AVAudioRecorder alloc] initWithURL:self.outputFileURL settings:self.recorderSetting error:NULL];
        _avRecorder.delegate = self;
        _avRecorder.meteringEnabled = YES;
    }
    return _avRecorder;
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
    NSTimeInterval duration = [self.stopTimestamp timeIntervalSinceDate:self.startTimestamp];
    if (duration < 0) // canceled
    {
        return;
    }

    if (flag && self.delegate)
    {
        [self.delegate recorder:self didRecordAudioFile:self.outputFileURL duration:duration];
    }
}

# pragma mark - Duration

- (void)_startDurationTimer
{
    [self _stopDurationTimer];

    dispatch_queue_t queue = dispatch_get_main_queue();
    self.durationTimer = [MSWeakTimer scheduledTimerWithTimeInterval:1
                                                            target:self
                                                          selector:@selector(_updateDuration)
                                                          userInfo:nil
                                                           repeats:YES
                                                     dispatchQueue:queue];
}

- (void)_stopDurationTimer
{
    if (self.durationTimer)
    {
        [self.durationTimer invalidate];
        self.durationTimer = nil;
    }
}

- (void)_updateDuration
{
    self.duration++;
    uint32_t minutes = self.duration / 60;
    uint32_t seconds = self.duration % 60;
    self.durationLabel.text = [NSString stringWithFormat:@"%u:%02u", minutes, seconds];
}

#pragma mark - animation

- (void)_playCancelAnimation
{
    [UIView animateKeyframesWithDuration:2.0 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.5 animations:^{
            self.imageView.backgroundColor = JoyyRedPure;
        }];

        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
            self.imageView.center = CGPointMake(200, 200);
        }];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];

    }];
}

- (void)_playStopAnimation
{
    [UIView animateKeyframesWithDuration:2.0 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.5 animations:^{
            self.imageView.image = [UIImage imageNamed:@"sound" maskedWithColor:JoyyGray];
            self.imageView.backgroundColor = ClearColor;
        }];

        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
            self.imageView.center = CGPointMake(SCREEN_WIDTH - 130, -20);
            self.imageView.backgroundColor = JoyyBlue;
        }];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
