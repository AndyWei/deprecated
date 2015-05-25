//
//  JYOrderItemView.h
//  joyyios
//
//  Created by Ping Yang on 4/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@import CoreLocation;

#import "JYBid.h"
#import "JYOrder.h"

@interface JYOrderItemView : UIControl

+ (CGFloat)viewHeightForOrder:(JYOrder *)order;
+ (CGFloat)viewHeightForBiddedOrder:(JYOrder *)order;

- (void)presentOrder:(JYOrder *)order;
- (void)presentBiddedOrder:(JYOrder *)order;

@property(nonatomic) BOOL tinyLabelsHidden;
@property(nonatomic) BOOL bidLabelHidden;

@property(nonatomic) UIColor *viewColor;
@property(nonatomic) UILabel *commentsLabel;

@end
