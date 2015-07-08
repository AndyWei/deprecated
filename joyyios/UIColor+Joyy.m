//
//  UIColor+Joyy.m
//  joyyios
//
//  Created by Ping Yang on 4/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "UIColor+Joyy.h"

@implementation UIColor (Joyy)

+ (UIColor *)joyyBlueColor
{
//    return hsb(204, 76, 86);
    return rgb(52, 181, 229);
}

+ (UIColor *)joyyBlueColor50
{
    return hsba(204, 76, 86, 0.5);
}

+ (UIColor *)joyyBlueLightColor
{
    return rgb(52, 181, 229);
}
@end
