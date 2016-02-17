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

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.contentImageView.image = nil;
}

- (void)fetchMessageImage
{
    [self.contentImageView sd_setImageWithURL:[NSURL URLWithString:self.message.URL]];
}

- (void)setMessage:(JYMessage *)message
{
    [super setMessage:message];

    if (self.contentImageView.superview)
    {
        [self.contentImageView removeFromSuperview];
    }

    self.contentImageView.frame = CGRectMake(0, 0, message.displayDimensions.width, message.displayDimensions.height);
    [self.mediaContainerView addSubview:self.contentImageView];
    [self.mediaContainerView pinAllEdgesOfSubview:self.contentImageView];

    [self fetchMessageImage];
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

@end
