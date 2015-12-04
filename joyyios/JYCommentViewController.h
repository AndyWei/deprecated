//
//  JYCommentViewController.h
//  joyyios
//
//  Created by Ping Yang on 5/20/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYComment.h"
#import "JYPost.h"
//#import "SLKTextViewController.h"

//@interface JYCommentViewController : SLKTextViewController
@interface JYCommentViewController : UITableViewController

- (instancetype)initWithPost:(JYPost *)post comment:(JYComment *)originalComment;

@end
