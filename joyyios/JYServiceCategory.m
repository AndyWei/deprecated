//
//  JYServiceCategory.m
//  joyyios
//
//  Created by Ping Yang on 4/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYServiceCategory.h"
#import "JYOrderCreateDetailsViewController.h"

@implementation JYServiceCategory

+ (NSArray *)names
{
    static NSArray *_names;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _names = @[
            NSLocalizedString(@"Cleaning", nil),
            NSLocalizedString(@"Delivery", nil),
            NSLocalizedString(@"Electrical", nil),
            NSLocalizedString(@"Handyman", nil),
            NSLocalizedString(@"Moving", nil),
            NSLocalizedString(@"Personal Assistant", nil),
            NSLocalizedString(@"Plumbing", nil),
            NSLocalizedString(@"Other", nil)
        ];
    });
    return _names;
}

+ (NSUInteger)categoryAtIndex:(JYServiceCategoryIndex)index
{
    // "Other" should be mapped to 0, means uncategorized
    if (index == [[self class] names].count - 1)
    {
        return 0;
    }
    return index + 1;
}

+ (JYServiceCategoryIndex)indexOfCategory:(NSUInteger)category
{
    if (category == 0)
    {
        return [[self class] names].count - 1;
    }
    return category - 1;
}

@end
