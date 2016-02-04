//
//  UITabBarItem+Joyy.m
//  joyyios
//
//  Created by Ping Yang on 1/20/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "UITabBarItem+Joyy.h"

const NSUInteger RED_DOT_TAG = 999;

@implementation UITabBarItem (Joyy)

- (void)showRedDot:(BOOL)show
{
    UIView *v = [self valueForKey:@"view"];

    for (UIView *sv in v.subviews)
    {
        NSString *str = NSStringFromClass([sv class]);
        if ([str isEqualToString:@"UITabBarSwappableImageView"])
        {
            for (UIView *ssv in sv.subviews)
            {
                if (ssv.tag == RED_DOT_TAG)
                {
                    ssv.alpha = show? 1.0 : 0.0;
                    return;
                }
            }

            if (!show)
            {
                return;
            }

            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 8, 8)];
            label.tag = RED_DOT_TAG;
            [label setText:@""];
            [label setBackgroundColor:JoyyRedPure];

            label.layer.cornerRadius = label.frame.size.height/2;
            label.layer.masksToBounds = YES;

            [sv addSubview:label];
        }
    }
}

@end
