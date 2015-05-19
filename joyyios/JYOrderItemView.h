//
//  JYOrderItemView.h
//  joyyios
//
//  Created by Ping Yang on 4/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@import CoreLocation;

@interface JYOrderItemView : UIView

+ (CGFloat)viewHeightForText:(NSString *)text;
+ (CGFloat)viewHeightForText:(NSString *)text withBid:(BOOL)bidded;

- (void)presentOrder:(NSDictionary *)order;
- (void)presentOrder:(NSDictionary *)order andBid:(NSDictionary *)bid;

@property(nonatomic) BOOL tinyLabelsHidden;
@property(nonatomic) BOOL bidLabelHidden;

@property(nonatomic) UIColor *viewColor;
@property(nonatomic) UILabel *commentsLabel;

@end
