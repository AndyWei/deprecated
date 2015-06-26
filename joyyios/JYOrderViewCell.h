//
//  JYOrderViewCell.h
//  joyyios
//
//  Created by Ping Yang on 6/21/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYOrder.h"

@interface JYOrderViewCell : UITableViewCell

+ (CGFloat)cellHeightForOrder:(JYOrder *)order;

@property(nonatomic) UIColor *cellColor;
@property(nonatomic, weak) JYOrder *order;

@end
