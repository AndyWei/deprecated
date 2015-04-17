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
    self.topLabel.backgroundColor = [UIColor whiteColor];
    self.topLabel.textColor = FlatGrayDark;
    self.topLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.topLabel];

    self.centerLabel = [[UILabel alloc] initWithFrame:frame];
    self.centerLabel.height = height * 0.6;
    self.centerLabel.y = CGRectGetMaxY(self.topLabel.frame);
    self.centerLabel.font = [UIFont systemFontOfSize:30];
    self.centerLabel.backgroundColor = [UIColor whiteColor];
    self.centerLabel.textColor = FlatGrayDark;
    self.centerLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.centerLabel];

    self.bottomLabel = [[UILabel alloc] initWithFrame:frame];
    self.bottomLabel.height = height * 0.2;
    self.bottomLabel.y = CGRectGetMaxY(self.centerLabel.frame);
    self.bottomLabel.font = [UIFont systemFontOfSize:10];
    self.bottomLabel.backgroundColor = [UIColor whiteColor];
    self.bottomLabel.textColor = FlatGrayDark;
    self.bottomLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.bottomLabel];

    self.layer.borderWidth = 1.0f;
    self.layer.cornerRadius = width * 0.5;
    self.layer.borderColor = FlatGrayDark.CGColor;

    self.backgroundColor = [UIColor whiteColor];
}

@end
