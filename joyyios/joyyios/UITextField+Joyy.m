//
//  UITextField+Joyy.m
//  joyyios
//
//  Created by Ping Yang on 9/11/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "UITextField+Joyy.h"

@implementation UITextField (Joyy)

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:NO];
    }];

    return [super canPerformAction:action withSender:sender];
}

@end
