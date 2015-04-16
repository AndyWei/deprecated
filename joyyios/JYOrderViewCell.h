//
//  JYOrderViewCell.h
//  joyyios
//
//  Created by Ping Yang on 4/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "MCSwipeTableViewCell.h"
#import "JYButton.h"

@interface JYOrderViewCell : MCSwipeTableViewCell

+ (CGFloat)cellHeight;
- (void)setStartDateTime:(NSDate *)date;

@property(nonatomic) JYButton *startDateButton;
@property(nonatomic) JYButton *startTimeButton;
@property(nonatomic) UILabel *titleLabel;
@property(nonatomic) UILabel *bodyLabel;
@property(nonatomic) UILabel *priceLabel;
@property(nonatomic) UILabel *placeLabel;
@property(nonatomic) UILabel *timeLabel;
@property(nonatomic) UILabel *distanceLabel;

@end
