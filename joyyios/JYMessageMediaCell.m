//
//  JYMessageOutgoingCell.m
//  joyyios
//
//  Created by Ping Yang on 2/15/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>

#import "JYMessageMediaCell.h"

@implementation JYMessageMediaCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self.contentView addSubview:self.mediaContainerView];
    }
    return self;
}

- (void)setMessage:(JYMessage *)message
{
    [super setMessage:message];

    [self _reset];

    switch (message.type)
    {
        case JYMessageTypeAudio:
            [self _setupAudioView];
            break;
        case JYMessageTypeImage:
            [self _setupImageView];
            break;

        default:
            break;
    }
}

- (void)_reset
{
    if (_audioPlayer && _audioPlayer.superview)
    {
        [_audioPlayer removeFromSuperview];
    }

    if (_contentImageView && _contentImageView.superview)
    {
        [_contentImageView removeFromSuperview];
    }
}

- (void)_setupImageView
{
    self.contentImageView.frame = CGRectMake(0, 0, self.message.displayDimensions.width, self.message.displayDimensions.height);
    [self.mediaContainerView addSubview:self.contentImageView];
    [self.mediaContainerView pinAllEdgesOfSubview:self.contentImageView];

    if (self.message.media)
    {
        self.contentImageView.image = self.message.media;
    }
    else
    {
        [self fetchMessageImage];
    }
}

- (void)_setupAudioView
{
    [self _updateTimeText];
    self.audioPlayer.url = [NSURL URLWithString:self.message.url];

    [self.mediaContainerView addSubview:self.audioPlayer];
    [self.mediaContainerView pinAllEdgesOfSubview:self.audioPlayer];

    if ([self.message.isOutgoing boolValue])
    {
        self.audioPlayer.backgroundColor = JoyyBlue;
        self.audioPlayer.layer.borderColor = JoyyBlue.CGColor;
        self.audioPlayer.imageView.image = [UIImage imageNamed:@"sound" maskedWithColor:JoyyGray];
    }
    else
    {
        self.audioPlayer.backgroundColor = JoyyWhitePure;
        self.audioPlayer.layer.borderColor = JoyyWhite.CGColor;
        self.audioPlayer.imageView.image = [UIImage imageNamed:@"sound" maskedWithColor:JoyyGray];
    }
}

- (void)_updateTimeText
{
    uint32_t seconds = (uint32_t)ceil(self.message.dimensions.width);
    uint32_t min = seconds / 60;
    uint32_t sec = seconds % 60;

    if (min == 0)
    {
        self.audioPlayer.textLabel.text = [NSString stringWithFormat:@"%.d\"", sec];
    }
    else
    {
        self.audioPlayer.textLabel.text = [NSString stringWithFormat:@"%.d\'%.d\"", min, sec];
    }
}

- (UIView *)mediaContainerView
{
    if (!_mediaContainerView)
    {
        _mediaContainerView = [UIView new];
        _mediaContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        _mediaContainerView.layer.cornerRadius = 12;
        _mediaContainerView.layer.masksToBounds= YES;
    }
    return _mediaContainerView;
}

- (UIImageView *)contentImageView
{
    if (!_contentImageView)
    {
        _contentImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _contentImageView.contentMode = UIViewContentModeScaleAspectFill;
        _contentImageView.layer.cornerRadius = 12;
        _contentImageView.layer.masksToBounds= YES;
    }
    return _contentImageView;
}

- (JYAudioPlayer *)audioPlayer
{
    if (!_audioPlayer)
    {
        _audioPlayer = [JYAudioPlayer new];
        _audioPlayer.layer.borderWidth = 0.5;
    }
    return _audioPlayer;
}

- (void)fetchMessageImage
{
    __weak typeof (self) weakSelf = self;
    [self.contentImageView sd_setImageWithURL:[NSURL URLWithString:self.message.url]
                             placeholderImage:self.message.media
                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                        weakSelf.contentImageView.image = image;
                                        weakSelf.message.media = image;
                                    }];
}

@end
