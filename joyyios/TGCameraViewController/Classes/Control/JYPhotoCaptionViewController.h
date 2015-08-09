//
//  JYPhotoCaptionViewController.h
//  joyyios
//
//  Created by Ping Yang on 7/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "SLKTextViewController.h"
#import "TGCamera.h"

@interface JYPhotoCaptionViewController : SLKTextViewController

- (instancetype)initWithDelegate:(id<TGCameraDelegate>)delegate photo:(UIImage *)photo;

@property (nonatomic) BOOL albumPhoto;

@end
