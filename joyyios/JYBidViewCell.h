//
//  JYBidViewCell.h
//  joyyios
//
//  Created by Ping Yang on 4/25/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//


@interface JYBidViewCell : UITableViewCell

+ (CGFloat)cellHeight;
- (void)setExpireTime:(NSTimeInterval)expireAt;
- (void)setRatingTotalScore:(NSUInteger)score count:(NSUInteger)count;

@property(nonatomic) UILabel *bidderNameLabel;
@property(nonatomic) UILabel *priceLabel;


@end