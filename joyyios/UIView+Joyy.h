//
//  UIView+Joyy.h
//  joyyios
//
//  Created by Ping Yang on 4/19/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//


@interface UIView (Joyy)

+ (UIView *)viewWithImageNamed:(NSString *)imageName;

- (void)pinSubview:(UIView *)subview toEdge:(NSLayoutAttribute)attribute;
- (void)pinAllEdgesOfSubview:(UIView *)subview;

@end
