//
//  JYCommentViewController.h
//  joyyios
//
//  Created by Ping Yang on 5/20/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYPost.h"
#import "SLKTextViewController.h"

@interface JYCommentViewController : SLKTextViewController

- (instancetype)initWithPost:(JYPost *)post withKeyboard:(BOOL)showKeyBoard;

@end
