//
//  JYCommentTextView.m
//  joyyios
//
//  Created by Ping Yang on 5/21/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
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

    self.backgroundColor = JoyyGrayDark;

    self.placeholder = NSLocalizedString(@"Add comment:", nil);
    self.placeholderColor = JoyyGray;
    self.pastableMediaTypes = SLKPastableMediaTypeAll;

    self.layer.borderColor = JoyyGrayDark.CGColor;
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;

    self.textColor = JoyyWhite;
    self.keyboardAppearance = UIKeyboardAppearanceDark;
}

@end
