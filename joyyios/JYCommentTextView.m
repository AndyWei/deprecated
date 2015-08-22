//
//  JYCommentTextView.m
//  joyyios
//
//  Created by Ping Yang on 5/21/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYCommentTextView.h"

@implementation JYCommentTextView

- (instancetype)init
{
    if (self = [super init])
    {
        // Do something
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    self.placeholder = NSLocalizedString(@"Add comment:", nil);
}

@end

