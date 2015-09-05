//
//  NSIndexPath+Joyy.m
//  joyyios
//
//  Created by Ping Yang on 9/4/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@implementation NSIndexPath (Joyy)

- (instancetype)previous
{
    if (self.section == 0 && self.item == 0)
    {
        return nil;
    }

    NSInteger item = self.item;
    NSInteger section = self.section;
    if (item == 0)
    {
        --section;
    }
    else
    {
        --item;
    }
    return [[self class] indexPathForItem:item inSection:section];
}

@end
