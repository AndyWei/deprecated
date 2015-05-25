//
//  JYCommentViewCell.h
//  joyyios
//
//  Created by Ping Yang on 5/14/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYComment.h"

@interface JYCommentViewCell : UITableViewCell <TTTAttributedLabelDelegate>

+ (CGFloat)cellHeightForComment:(JYComment *)comment;
- (void)presentComment:(JYComment *)comment;

@end
