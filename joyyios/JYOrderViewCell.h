//
//  JYOrderViewCell.h
//  joyyios
//
//  Created by Ping Yang on 6/21/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYInvite.h"

@interface JYOrderViewCell : UITableViewCell

+ (CGFloat)heightForOrder:(JYInvite *)order;

@property(nonatomic) UIColor *color;
@property(nonatomic, weak) JYInvite *order;

@end
