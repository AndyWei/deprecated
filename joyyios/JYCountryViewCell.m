//
//  JYCountryViewCell.m
//  joyyios
//
//  Created by Ping Yang on 9/11/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYCountryViewCell.h"

@interface JYCountryViewCell ()
@property (nonatomic) UIImageView *checkMarkImageView;
@property (nonatomic) TTTAttributedLabel *countryNameLabel;
@property (nonatomic) TTTAttributedLabel *countryNumberLabel;
@end

static const CGFloat kCheckMarkImageWidth = 20;

@implementation JYCountryViewCell


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = JoyyWhitePure;
    }
    return self;
}

- (void)presentCountry:(NSString *)country dialingCode:(NSString *)dialingCode selected:(BOOL)selected
{
    self.countryNameLabel.text = country;
    self.countryNumberLabel.text = [NSString stringWithFormat:@"+%@", dialingCode];
    self.checkMarkImageView.image = selected? [UIImage imageNamed:@"checkMark"] : nil;
}

- (TTTAttributedLabel *)countryNameLabel
{
    if (!_countryNameLabel)
    {
        CGRect frame = CGRectMake(kMarginLeft, 0, self.width * 0.7, self.height);
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
        label.font = [UIFont systemFontOfSize:16];
        label.textAlignment = NSTextAlignmentLeft;
        [self addSubview:label];

        _countryNameLabel = label;

    }
    return _countryNameLabel;
}

- (TTTAttributedLabel *)countryNumberLabel
{
    if (!_countryNumberLabel)
    {
        CGFloat x = CGRectGetMaxX(self.countryNameLabel.frame);
        CGFloat width = self.checkMarkImageView.x - x;
        CGRect frame = CGRectMake(x, 0, width, self.height);

        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
        label.font = [UIFont systemFontOfSize:16];
        label.textAlignment = NSTextAlignmentRight;
        label.textColor = JoyyGrayDark;

        [self addSubview:label];
        _countryNumberLabel = label;
    }
    return _countryNumberLabel;
}

- (UIImageView *)checkMarkImageView
{
    if (!_checkMarkImageView)
    {
        CGFloat x = self.width - 30 - kCheckMarkImageWidth;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, 13, kCheckMarkImageWidth, kCheckMarkImageWidth)];
        [self addSubview:imageView];

        _checkMarkImageView = imageView;
    }

    return _checkMarkImageView;
}

@end

