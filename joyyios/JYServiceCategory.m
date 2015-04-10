//
//  JYServiceCategory.m
//  joyyios
//
//  Created by Ping Yang on 4/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYServiceCategory.h"
#import "JYOrderCreateRoadSideViewController.h"

@implementation JYServiceCategory

+ (NSArray *)names
{
    static NSArray *_names;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _names = @[
            NSLocalizedString(@"Roadside Assistance", nil),
            NSLocalizedString(@"Ride", nil),
            NSLocalizedString(@"Moving", nil),
            NSLocalizedString(@"Delivery", nil),
            NSLocalizedString(@"Plumbing", nil),
            NSLocalizedString(@"Cleaning", nil),
            NSLocalizedString(@"Handyman", nil),
            NSLocalizedString(@"Gardener", nil),
            NSLocalizedString(@"Personal Assistant", nil),
            NSLocalizedString(@"Other", nil)
        ];
    });
    return _names;
}

+ (NSUInteger)categoryAtIndex:(NSUInteger)index
{
    // "Other" should be mapped to 0, means uncategorized
    if (index == [[self class] names].count - 1)
    {
        return 0;
    }
    return index + 1;
}

+ (NSArray *)viewControllerClasses
{
    static NSArray *_viewControllerClasses;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _viewControllerClasses = @[
            [JYOrderCreateRoadSideViewController class],
            [JYOrderCreateRoadSideViewController class],
            [JYOrderCreateRoadSideViewController class],
            [JYOrderCreateRoadSideViewController class],
            [JYOrderCreateRoadSideViewController class],
            [JYOrderCreateRoadSideViewController class],
            [JYOrderCreateRoadSideViewController class],
            [JYOrderCreateRoadSideViewController class],
            [JYOrderCreateRoadSideViewController class],
            [JYOrderCreateRoadSideViewController class]
        ];
    });
    return _viewControllerClasses;
}

+ (Class)classAtIndex:(NSUInteger)index
{
    return [[self class] viewControllerClasses][index];
}

@end
