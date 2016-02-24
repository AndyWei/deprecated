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

#import "JYButton.h"
#import "JYAudioRecorder.h"

@interface JYAudioRecorder () <AVAudioRecorderDelegate, UIScrollViewDelegate>
@property (nonatomic) AVAudioRecorder *avRecorder;
@property (nonatomic) NSDate *startTimestamp;
@property (nonatomic) NSDate *stopTimestamp;
@property (nonatomic) NSDictionary *recorderSetting;
@property (nonatomic) NSURL *outputFileURL;

@property (nonatomic) JYButton *slideButton;
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
        [self addSubview:self.scrollView];
        [self addSubview:self.durationLabel];

        NSDictionary *views = @{
                                @"imageView": self.imageView,
                                @"scrollView": self.scrollView,
                                @"durationLabel": self.durationLabel
                                };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imageView(25)]-15-[durationLabel(50)]-3-[scrollView]-0-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0@500)-[imageView(25)]-(>=0@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0@500)-[durationLabel]-(>=0@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0@500)-[scrollView]-(>=0@500)-|" options:0 metrics:nil views:views]];

        [self pinCenterYOfSubviews:@[self.imageView, self.durationLabel, self.scrollView]];
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

- (UIScrollView *)scrollView
{
    if (!_scrollView)
    {
        _scrollView = [UIScrollView new];
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _scrollView.delegate = self;
        [_scrollView addSubview:self.slideButton];
        _scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.slideButton.frame), CGRectGetHeight(self.slideButton.frame));
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
    }
    return _scrollView;
}

- (JYButton *)slideButton
{
    if (!_slideButton)
    {
        CGRect frame = CGRectMake(0, 0, 1600, 44);
        JYButton *button = [[JYButton alloc] initWithFrame:frame buttonStyle:JYButtonStyleTitle];
        button.textLabel.text = NSLocalizedString(@"    slide to cancel <", nil);
        button.textLabel.textAlignment = NSTextAlignmentLeft;
        button.contentColor = JoyyGray;
        _slideButton = button;
    }
    return _slideButton;
}

- (void)start
{
    [self.avRecorder record];
    self.startTimestamp = [NSDate date];
    self.duration = 0;

    // duration label
    self.durationLabel.text = @"0:00";
    [self _startDurationTimer];

    // scroll view
    self.scrollView.contentOffset = CGPointMake(0, 0);

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
    self.imageView.image = [UIImage imageNamed:@"sound" maskedWithColor:JoyyBlue];
    self.imageView.backgroundColor = ClearColor;

    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation.calculationMode = kCAAnimationPaced;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = YES;
    animation.repeatCount = 1;
    animation.rotationMode = @"auto";
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.duration = 1.0;

    // path
    CGPoint startPoint = self.imageView.center;
    CGPoint endPoint = CGPointMake(SCREEN_WIDTH - 130, 0);
    CGPoint centerPoint = CGPointMake((startPoint.x + endPoint.x)/2, (startPoint.y + endPoint.y)/2);
    CGFloat radius = (endPoint.x - startPoint.x) / 2;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:startPoint];

    [path addArcWithCenter:centerPoint radius:radius startAngle:(M_PI) endAngle:0 clockwise:YES];
    animation.path = path.CGPath;

    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self removeFromSuperview];
    }];
    [self.imageView.layer addAnimation:animation forKey:@"recordingDoneAnimation"];
    [CATransaction commit];
}

@end
