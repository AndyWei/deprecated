//
//  JYDateTimeView.m
//  joyyios
//
//  Created by Ping Yang on 4/16/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYDateView.h"

@implementation JYDateView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self != nil)
    {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit
{
    CGFloat width = CGRectGetHeight(self.frame);
    CGFloat height = width * 0.8;
    CGRect frame = CGRectMake(width * 0.1, width * 0.1, height, height);

    UILabel *topLabel = [[UILabel alloc] initWithFrame:frame];
    topLabel.height = height * 0.2;
    topLabel.font = [UIFont systemFontOfSize:10];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.userInteractionEnabled = NO;
    self.topLabel = topLabel;
    [self addSubview:self.topLabel];

    UILabel *centerLabel = [[UILabel alloc] initWithFrame:frame];
    centerLabel.height = height * 0.6;
    centerLabel.y = CGRectGetMaxY(self.topLabel.frame);
    centerLabel.font = [UIFont systemFontOfSize:30];
    centerLabel.textAlignment = NSTextAlignmentCenter;
    centerLabel.userInteractionEnabled = NO;
    self.centerLabel = centerLabel;
    [self addSubview:self.centerLabel];

    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:frame];
    bottomLabel.height = height * 0.2;
    bottomLabel.y = CGRectGetMaxY(self.centerLabel.frame);
    bottomLabel.font = [UIFont systemFontOfSize:10];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.userInteractionEnabled = NO;
    self.bottomLabel = bottomLabel;
    [self addSubview:self.bottomLabel];

    self.layer.borderWidth = 1.0f;
    self.layer.cornerRadius = width * 0.5;
    self.layer.borderColor = FlatGrayDark.CGColor;

    self.textColor = FlatGrayDark;
    self.userInteractionEnabled = NO;
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    self.topLabel.textColor = textColor;
    self.centerLabel.textColor = textColor;
    self.bottomLabel.textColor = textColor;
}

@end
