//
//  JYCommentViewCell.h
//  joyyios
//
//  Created by Ping Yang on 5/14/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYComment.h"

@interface JYCommentViewCell : UITableViewCell

+ (CGFloat)heightForComment:(JYComment *)comment;

@property(nonatomic) JYComment *comment;

@end
