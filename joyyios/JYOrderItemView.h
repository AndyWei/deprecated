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
- (void)presentOrder:(NSDictionary *)order;

- (void)setStartDateTime:(NSDate *)date;
- (void)setCreateTime:(NSString *)dateString;
- (void)setDistanceFromPoint:(CLLocationCoordinate2D )point;

@property(nonatomic) BOOL tinylabelsHidden;
@property(nonatomic) UIColor *viewColor;
@property(nonatomic) UILabel *bodyLabel;
@property(nonatomic) UILabel *cityLabel;
@property(nonatomic) UILabel *commentsLabel;
@property(nonatomic) UILabel *priceLabel;
@property(nonatomic) UILabel *titleLabel;

@end
