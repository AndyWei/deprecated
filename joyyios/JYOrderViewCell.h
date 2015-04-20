//
//  JYOrderViewCell.h
//  joyyios
//
//  Created by Ping Yang on 4/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <MCSwipeTableViewCell/MCSwipeTableViewCell.h>

#import "JYDateView.h"

@interface JYOrderViewCell : MCSwipeTableViewCell

+ (CGFloat)cellHeightForText:(NSString *)text;
- (void)setStartDateTime:(NSDate *)date;
- (void)setCreateTime:(NSString *)dateString;
- (void)setDistanceFromPoint:(CLLocationCoordinate2D )point;

@property(nonatomic) JYDateView *startDateView;
@property(nonatomic) UILabel *startTimeLabel;
@property(nonatomic) UILabel *titleLabel;
@property(nonatomic) UILabel *bodyLabel;
@property(nonatomic) UILabel *priceLabel;
@property(nonatomic) UILabel *cityLabel;
@property(nonatomic) UILabel *timeLabel;
@property(nonatomic) UILabel *distanceLabel;

@end
