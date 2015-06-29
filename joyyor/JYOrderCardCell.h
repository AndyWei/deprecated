//
//  JYOrderCardCell.h
//  joyyor
//
//  Created by Ping Yang on 4/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <MCSwipeTableViewCell/MCSwipeTableViewCell.h>

#import "JYOrder.h"

@interface JYOrderCardCell : MCSwipeTableViewCell

+ (CGFloat)heightForOrder:(JYOrder *)order withAddress:(BOOL)showAddress andBid:(BOOL)showBid;

@property(nonatomic) UIColor *cardColor;

- (void)presentOrder:(JYOrder *)order withAddress:(BOOL)showAddress andBid:(BOOL)showBid;
- (void)updateCommentsCount:(NSUInteger)count;

@end
