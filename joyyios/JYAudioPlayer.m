//
//  JYAudioPlayer.m
//  joyyios
//
//  Created by Ping Yang on 2/20/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "JYAudioPlayer.h"

@interface JYAudioPlayer ()
@property (nonatomic) AVPlayer *player;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic, getter=isTrackingInside) BOOL trackingInside;
@end

@implementation JYAudioPlayer

- (instancetype)init
{
    if (self = [super init])
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.trackingInside = NO;

        [self addSubview:self.imageView];
        [self addSubview:self.textLabel];

        NSDictionary *views = @{
                                @"imageView": self.imageView,
                                @"textLabel": self.textLabel
                                };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imageView(25)]-10-[textLabel]-10-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0@500)-[imageView(25)]-(>=0@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0@500)-[textLabel]-(>=0@500)-|" options:0 metrics:nil views:views]];

        [self pinCenterYOfSubviews:@[self.imageView, self.textLabel]];

        // action
        [self addTarget:self action:@selector(_action) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)_action
{
    if (!self.url || !self.player)
    {
        return;
    }

    if (self.isPlaying)
    {
        [self.player pause];
        self.isPlaying = NO;
    }
    else
    {
        [self.player play];
        self.isPlaying = YES;
    }
}

- (void)setUrl:(NSURL *)url
{
    _url = url;
    self.player = [[AVPlayer alloc] initWithURL:url];
//    [self.player addObserver:self forKeyPath:@"status" options:0 context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
}

- (void)_playerItemDidReachEnd:(NSNotification *)notification
{
    self.isPlaying = NO;
}

- (UIImageView *)imageView
{
    if (!_imageView)
    {
        _imageView = [UIImageView new];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.image = [UIImage imageNamed:@"sound"];
    }
    return _imageView;
}

- (TTTAttributedLabel *)textLabel
{
    if (!_textLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:14];
        label.backgroundColor = ClearColor;
        label.textColor = JoyyWhite;
        _textLabel = label;
    }
    return _textLabel;
}

#pragma mark - Touchs

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if ([self pointInside:point withEvent:event])
    {
        return self;
    }

    return [super hitTest:point withEvent:event];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    self.trackingInside = YES;
    self.selected = !self.selected;
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL wasTrackingInside = self.trackingInside;
    self.trackingInside = [self isTouchInside];

    if (wasTrackingInside != self.isTrackingInside)
    {
        self.selected = !self.selected;
    }

    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    self.trackingInside = [self isTouchInside];
    if (self.isTrackingInside)
    {
        self.selected = !self.selected;
    }

    self.trackingInside = NO;
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    self.trackingInside = [self isTouchInside];
    if (self.isTrackingInside)
    {
        self.selected = !self.selected;
    }

    self.trackingInside = NO;
    [super cancelTrackingWithEvent:event];
}

@end

