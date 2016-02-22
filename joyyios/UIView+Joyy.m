//
//  UIView+Joyy.m
//  joyyios
//
//  Created by Ping Yang on 4/19/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "UIView+Joyy.h"

@implementation UIView (Joyy)

+ (UIView *)viewWithImageNamed:(NSString *)imageName
{
    UIImage *image = [UIImage imageNamed:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    return imageView;
}

- (void)pinSubview:(UIView *)subview to:(NSLayoutAttribute)attribute
{
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:attribute
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:subview
                                                     attribute:attribute
                                                    multiplier:1.0f
                                                      constant:0.0f]];
}

- (void)pinAllEdgesOfSubview:(UIView *)subview
{
    [self pinSubview:subview to:NSLayoutAttributeBottom];
    [self pinSubview:subview to:NSLayoutAttributeTop];
    [self pinSubview:subview to:NSLayoutAttributeLeading];
    [self pinSubview:subview to:NSLayoutAttributeTrailing];
}

- (void)pinCenterXOfSubviews:(NSArray *)subviews
{
    for (UIView *view in subviews)
    {
        [self pinSubview:view to:NSLayoutAttributeCenterX];
    }
}

- (void)pinCenterYOfSubviews:(NSArray *)subviews
{
    for (UIView *view in subviews)
    {
        [self pinSubview:view to:NSLayoutAttributeCenterY];
    }
}

@end
