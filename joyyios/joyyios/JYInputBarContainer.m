//
//  JYInputBarContainer.m
//  joyyios
//
//  Created by Ping Yang on 2/18/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "JYInputBarContainer.h"

@implementation JYInputBarContainer

- (instancetype)initWithCameraImage:(UIImage *)camera micImage:(UIImage *)mic
{
    if (self = [super init])
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.cameraButton = [self buttonWithImage:camera];
        self.micButton = [self buttonWithImage:mic];

        [self addSubview:self.cameraButton];
        [self addSubview:self.micButton];

        NSDictionary *views = @{
                                @"cameraButton": self.cameraButton,
                                @"micButton": self.micButton
                                };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[cameraButton]-20-[micButton]-10-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[cameraButton]-0-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[micButton]-0-|" options:0 metrics:nil views:views]];

        // cameraButton and micButton splict the width equally
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.micButton
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.cameraButton
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:1.0f
                                                          constant:0.0f]];
    }
    return self;
}

- (JYButton *)buttonWithImage:(UIImage *)image
{
    JYButton *button = [JYButton iconButtonWithFrame:CGRectZero icon:image color:JoyyBlue];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    return button;
}

@end
