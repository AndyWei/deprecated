//
//  JYOrderItemView.h
//  joyyios
//
//  Created by Ping Yang on 4/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYDateView.h"

@interface JYOrderItemView : UIView

+ (CGFloat)viewHeightForText:(NSString *)text;
- (void)setStartDateTime:(NSDate *)date;

@property(nonatomic) UILabel *titleLabel;
@property(nonatomic) UILabel *bodyLabel;
@property(nonatomic) UILabel *priceLabel;

@end
