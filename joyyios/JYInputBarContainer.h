//
//  JYInputBarContainer.h
//  joyyios
//
//  Created by Ping Yang on 2/18/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "JYButton.h"

@interface JYInputBarContainer : UIView

- (instancetype)initWithCameraImage:(UIImage *)camera micImage:(UIImage *)mic;

@property (nonatomic) JYButton *cameraButton;
@property (nonatomic) JYButton *micButton;

@end
