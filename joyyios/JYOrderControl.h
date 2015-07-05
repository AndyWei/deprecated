//
//  JYOrderControl.h
//  joyyios
//
//  Created by Ping Yang on 6/29/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYInvite.h"

@interface JYOrderControl : UIControl

+ (CGFloat)heightForOrder:(JYInvite *)order;

@property(nonatomic) UIColor *color;
@property(nonatomic, weak) JYInvite *order;

@end
