//
//  JYOrderViewCell.h
//  joyyor
//
//  Created by Ping Yang on 4/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <MCSwipeTableViewCell/MCSwipeTableViewCell.h>

#import "JYOrder.h"

@interface JYOrderViewCell : MCSwipeTableViewCell

+ (CGFloat)cellHeightForOrder:(JYOrder *)order;
- (void)presentOrder:(JYOrder *)order;
- (void)presentBiddedOrder:(JYOrder *)order;
- (void)updateCommentsCount:(NSUInteger)count;

@end
