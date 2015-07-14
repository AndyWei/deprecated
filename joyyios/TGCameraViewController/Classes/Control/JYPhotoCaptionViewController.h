//
//  JYPhotoCaptionViewController.h
//  joyyios
//
//  Created by Ping Yang on 7/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "TGCamera.h"

@interface JYPhotoCaptionViewController : UITableViewController

+ (instancetype)new __attribute__
((unavailable("[+new] is not allowed, use [+newWithDelegate:photo:]")));

- (instancetype) init __attribute__
((unavailable("[-init] is not allowed, use [+newWithDelegate:photo:]")));

+ (instancetype)newWithDelegate:(id<TGCameraDelegate>)delegate photo:(UIImage *)photo;


@property (nonatomic) BOOL albumPhoto;

@end
