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

    self.topLabel = [[UILabel alloc] initWithFrame:frame];
    self.topLabel.height = height * 0.2;
    self.centerLabel.y = (width - height) * 0.5;
    self.topLabel.font = [UIFont systemFontOfSize:10];
    self.topLabel.textAlignment = NSTextAlignmentCenter;
    self.topLabel.userInteractionEnabled = NO;
    [self addSubview:self.topLabel];

    self.centerLabel = [[UILabel alloc] initWithFrame:frame];
    self.centerLabel.height = height * 0.6;
    self.centerLabel.y = CGRectGetMaxY(self.topLabel.frame);
    self.centerLabel.font = [UIFont systemFontOfSize:30];
    self.centerLabel.textAlignment = NSTextAlignmentCenter;
    self.centerLabel.userInteractionEnabled = NO;
    [self addSubview:self.centerLabel];

    self.bottomLabel = [[UILabel alloc] initWithFrame:frame];
    self.bottomLabel.height = height * 0.2;
    self.bottomLabel.y = CGRectGetMaxY(self.centerLabel.frame);
    self.bottomLabel.font = [UIFont systemFontOfSize:10];
    self.bottomLabel.textAlignment = NSTextAlignmentCenter;
    self.bottomLabel.userInteractionEnabled = NO;
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
