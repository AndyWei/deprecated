//
//  UIImage+Joyy.h
//  joyyios
//
//  Created by Ping Yang on 2/16/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

@interface UIImage (Joyy)

+ (instancetype)imageNamed:(NSString *)name maskedWithColor:(UIColor *)maskColor;
- (instancetype)imageMaskedWithColor:(UIColor *)maskColor;

@end
