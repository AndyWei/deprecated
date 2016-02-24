//
//  UIImage+Joyy.m
//  joyyios
//
//  Created by Ping Yang on 2/16/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "UIImage+Joyy.h"

@implementation UIImage (Joyy)

+ (instancetype)imageNamed:(NSString *)name maskedWithColor:(UIColor *)maskColor
{
    UIImage *image = [UIImage imageNamed:name];
    return [image imageMaskedWithColor:maskColor];
}

- (instancetype)imageMaskedWithColor:(UIColor *)maskColor
{
    NSParameterAssert(maskColor != nil);

    CGRect imageRect = CGRectMake(0.0f, 0.0f, self.size.width, self.size.height);
    UIImage *newImage = nil;

    UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, self.scale);
    {
        CGContextRef context = UIGraphicsGetCurrentContext();

        CGContextScaleCTM(context, 1.0f, -1.0f);
        CGContextTranslateCTM(context, 0.0f, -(imageRect.size.height));

        CGContextClipToMask(context, imageRect, self.CGImage);
        CGContextSetFillColorWithColor(context, maskColor.CGColor);
        CGContextFillRect(context, imageRect);

        newImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();

    return newImage;
}

@end
