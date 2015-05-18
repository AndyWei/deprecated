//
//  JYCommentViewCell.h
//  joyyios
//
//  Created by Ping Yang on 5/14/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

@interface JYCommentViewCell : UITableViewCell <TTTAttributedLabelDelegate>

+ (CGFloat)cellHeightForComment:(NSDictionary *)comment;
- (void)presentComment:(NSDictionary *)comment;

@end
