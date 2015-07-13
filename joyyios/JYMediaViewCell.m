//
//  JYMediaViewCell.m
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYMedia.h"
#import "JYMediaViewCell.h"

static const CGFloat kActionBarHeight = 40;
static const CGFloat kCaptionMinHeight = 40;

@interface JYMediaViewCell ()

@property(nonatomic, weak) UIImageView *photoView;
@property(nonatomic, weak) UIView *actionBar;
@property(nonatomic, weak) UILabel *captionLabel;

@end


@implementation JYMediaViewCell


+ (CGFloat)heightForMedia:(JYMedia *)media;
{
    return SCREEN_WIDTH + kActionBarHeight + kCaptionMinHeight;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = JoyyWhite;

        [self _createPhotoView];
        [self _createCaptionLabel];
    }
    return self;
}

- (void)setMedia:(JYMedia *)media
{
    self.captionLabel.text = media.caption;
    self.photoView.image = [UIImage imageNamed: media.url];
}

- (void)_createPhotoView
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH)];
    [self addSubview:imageView];
    self.photoView = imageView;
}

- (void)_createCaptionLabel
{
    self.captionLabel = [self _createLabel];
    self.captionLabel.frame = CGRectMake(0, 0, SCREEN_WIDTH, kCaptionMinHeight);
}

- (UILabel *)_createLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.backgroundColor = JoyyWhite;
    label.font = [UIFont systemFontOfSize:16];
    label.textColor = FlatBlack;
    label.textAlignment = NSTextAlignmentCenter;
    [self addSubview:label];

    return label;
}

@end
