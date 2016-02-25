//
//  JYAudioPlayer.m
//  joyyios
//
//  Created by Ping Yang on 2/20/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "JYAudioPlayer.h"
#import "JYButton.h"

@interface JYAudioPlayer () <AVAudioPlayerDelegate>
@property (nonatomic) NSURL *fileURL;
@property (nonatomic) NSURL *remoteURL;
@property (nonatomic) UIColor *foregroundColor;

@property (nonatomic) AVAudioPlayer *player;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) JYButton *button;
@end

@implementation JYAudioPlayer

- (instancetype)init
{
    if (self = [super init])
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;

        [self addSubview:self.button];

        NSDictionary *views = @{
                                @"button": self.button
                                };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[button(100)]-10-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[button(35)]-0-|" options:0 metrics:nil views:views]];

        [self.button addTarget:self action:@selector(_action) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (JYButton *)button
{
    if (!_button)
    {
        _button = [[JYButton alloc] initWithFrame:CGRectZero buttonStyle:JYButtonStyleImageWithTitle];
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        _button.imageView.image = [UIImage imageNamed:@"sound" maskedWithColor:JoyyGray];
        _button.contentColor = JoyyGray;
    }
    return _button;
}

- (void)_action
{
    if (self.isPlaying)
    {
        [self.player pause];
        self.isPlaying = NO;
        self.button.contentColor = JoyyGray;
        return;
    }

    if (self.fileURL)
    {
        [self.player play];
        self.isPlaying = YES;
        self.button.contentColor = JoyyWhite;
        return;
    }

    if (self.remoteURL)
    {
        [self _downloadAndPlay];
    }
}

- (void)setMessage:(JYMessage *)message
{
    _message = message;
    [self _updateTimeText];

    if ([_message.isOutgoing boolValue])
    {
        self.foregroundColor = JoyyBlue;
        self.layer.borderColor = JoyyBlue.CGColor;
    }
    else
    {
        self.foregroundColor = JoyyWhitePure;
        self.layer.borderColor = JoyyWhite.CGColor;
    }

    self.fileURL = _message.media;
    self.remoteURL = [NSURL URLWithString:_message.url];
}

- (void)_updateTimeText
{
    uint32_t seconds = (uint32_t)ceil(self.message.dimensions.width);
    uint32_t min = seconds / 60;
    uint32_t sec = seconds % 60;

    if (min == 0)
    {
         self.button.textLabel.text = [NSString stringWithFormat:@"%.d\"", sec];
    }
    else
    {
         self.button.textLabel.text = [NSString stringWithFormat:@"%.d\'%.d\"", min, sec];
    }
}

- (void)setFileURL:(NSURL *)fileURL
{
    _fileURL = fileURL;

    NSError *error;
    self.player = [[AVAudioPlayer alloc]initWithContentsOfURL:fileURL error:&error];
    self.player.delegate = self;
    self.isPlaying = NO;
}

- (void)setForegroundColor:(UIColor *)foregroundColor
{
    _foregroundColor = foregroundColor;
    self.backgroundColor = foregroundColor;
    self.button.foregroundColor = foregroundColor;
}

- (void)_downloadAndPlay
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

    NSURLRequest *request = [NSURLRequest requestWithURL:self.remoteURL];

    __weak typeof(self) weakSelf = self;
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [NSURL temporaryFileURLWithFilename:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"File downloaded to: %@", filePath);
        weakSelf.fileURL = filePath;
        weakSelf.message.media = filePath;
        [weakSelf.player play];
    }];
    [downloadTask resume];
}

#pragma mark AVAudioPlayerDelegate methods

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    self.isPlaying = NO;
    self.button.contentColor = JoyyGray;
}

@end

