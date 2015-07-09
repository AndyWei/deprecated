//
//  JYCameraOverlayView.m
//  joyyios
//
//  Created by Ping Yang on 7/8/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYCameraOverlayView.h"

@implementation JYCameraOverlayView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        //clear the background color of the overlay
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];

        //load an image to show in the overlay

        UIImage *overlayImage = [UIImage imageNamed:@"search"];
        UIImageView *overlayImageView = [[UIImageView alloc] initWithImage:overlayImage];
        overlayImageView.frame = frame;
        overlayImageView.backgroundColor = JoyyWhite;
        [self addSubview:overlayImageView];
        
    }
    
    return self;
}

@end
