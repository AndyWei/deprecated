//
//  JYPhotoCaptionViewController.h
//  joyyios
//
//  Created by Ping Yang on 7/13/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <SlackTextViewController/SLKTextViewController.h>
#import "TGCamera.h"

@interface JYPhotoCaptionViewController : SLKTextViewController <TGCaptionViewControllerInterface>

- (instancetype)initWithDelegate:(id<TGCameraDelegate>)delegate;

@property (nonatomic) BOOL isFromAlbum;
@property (nonatomic) UIImage *photo;

@end
