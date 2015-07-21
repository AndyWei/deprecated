//
//  JYCommentViewController.h
//  joyyios
//
//  Created by Ping Yang on 5/20/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYMedia.h"
#import "SLKTextViewController.h"

@interface JYCommentViewController : SLKTextViewController

- (instancetype)initWithMedia:(JYMedia *)media withKeyboard:(BOOL)showKeyBoard;

@end
