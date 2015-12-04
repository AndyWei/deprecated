//
//  JYCaptionTextView.m
//  joyyios
//
//  Created by Andy Wei on 8/8/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYCaptionTextView.h"

@implementation JYCaptionTextView

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

    self.backgroundColor = JoyyWhite;

    self.placeholder = NSLocalizedString(@"Add caption:", nil);
    self.placeholderColor = JoyyGray;
    self.pastableMediaTypes = SLKPastableMediaTypeAll;

    self.layer.borderColor = JoyyWhite.CGColor;
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

@end
