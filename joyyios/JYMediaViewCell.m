//
//  JYMediaViewCell.m
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>

#import "JYMedia.h"
#import "JYMediaViewCell.h"

static const CGFloat kActionBarHeight = 40;
static const CGFloat kCaptionMinHeight = 40;
static const CGFloat kCommentCountLabelHeight = 40;

@interface JYMediaViewCell ()

@property(nonatomic) UIImageView *photoView;
@property(nonatomic) UIView *actionBar;
@property(nonatomic) UILabel *captionLabel;

@end


@implementation JYMediaViewCell

+ (CGFloat)labelHeightForText:(NSString *)text withFontSize:(CGFloat)fontSize
{
    CGFloat labelWidth = SCREEN_WIDTH - kMarginLeft - kMarginRight;
    CGSize maximumSize = CGSizeMake(labelWidth, 10000);

    static UILabel *dummyLabel = nil;
    if (!dummyLabel)
    {
        dummyLabel = [UILabel new];
        dummyLabel.font = [UIFont systemFontOfSize:fontSize];
        dummyLabel.textAlignment = NSTextAlignmentCenter;
        dummyLabel.numberOfLines = 0;
        dummyLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    dummyLabel.text = text;
    CGSize expectSize = [dummyLabel sizeThatFits:maximumSize];
    CGFloat labelHeight = fmax(expectSize.height, kCaptionMinHeight);

    return labelHeight;
}

+ (CGFloat)heightForMedia:(JYMedia *)media;
{
    CGFloat imageHeight = SCREEN_WIDTH;
    CGFloat captionHeight = [JYMediaViewCell labelHeightForText:media.caption withFontSize:kFontSizeBody];
    return imageHeight + captionHeight + kActionBarHeight + kCommentCountLabelHeight;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = JoyyBlack;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setMedia:(JYMedia *)media
{
    self.captionLabel.text = media.caption;
    self.captionLabel.height = [JYMediaViewCell labelHeightForText:media.caption withFontSize:kFontSizeBody];

    // Use local image
    if (media.localImage)
    {
        self.photoView.image = media.localImage;
        return;
    }

    // Fetch network image
    NSURL *url = [NSURL URLWithString:media.url];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    __weak typeof(self) weakSelf = self;
    [self.photoView setImageWithURLRequest:request
                          placeholderImage:nil
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
                                   {
                                       weakSelf.photoView.image = image;
                                       [weakSelf setNeedsLayout];

                                   } failure:nil];
}

- (UIImageView *)photoView
{
    if (!_photoView)
    {
        _photoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH)];
        _photoView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_photoView];
    }
    return _photoView;
}

- (UILabel *)captionLabel
{
    if (!_captionLabel)
    {
        _captionLabel = [self _createLabel];
        _captionLabel.y = CGRectGetMaxY(self.photoView.frame);
        [self addSubview:_captionLabel];
    }
    return _captionLabel;
}

- (UILabel *)_createLabel
{
    CGFloat width = SCREEN_WIDTH - kMarginLeft - kMarginRight;
    CGRect frame = CGRectMake(kMarginLeft, 0, width, 0);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = JoyyBlack;
    label.font = [UIFont systemFontOfSize:kFontSizeBody];
    label.textColor = JoyyWhite;
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;

    return label;
}

@end
