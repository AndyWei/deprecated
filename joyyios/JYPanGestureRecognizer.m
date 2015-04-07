//
//  JYPanGestureRecognizer.m
//  joyyios
//
//  Created by Ping Yang on 4/2/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYPanGestureRecognizer.h"
#import "JYPinchGestureRecognizer.h"

@interface JYPanGestureRecognizer ()

@property(nonatomic) CGVector move;

@end

@implementation JYPanGestureRecognizer

- (instancetype)init
{
    self = [super initWithTarget:self action:@selector(_handlePanGesture:)];

    return self;
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]])
    {
        return YES;
    }
    return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    return NO;
}

- (void)_handlePanGesture:(JYPanGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        sender.move = CGVectorMake(0, 0);
        if (sender.delegate && [sender.delegate respondsToSelector:@selector(panGestureBegin)])
        {
            [sender.delegate panGestureBegin];
        }
    }
    else if (sender.state == UIGestureRecognizerStateChanged)
    {
        // Do nothing. The mapview has scroll enabled and will handle scrolling by itself.
    }
    else
    {
        if (sender.delegate && [sender.delegate respondsToSelector:@selector(panGestureEnd)])
        {
            [sender.delegate panGestureEnd];
        }
    }
}

@end
