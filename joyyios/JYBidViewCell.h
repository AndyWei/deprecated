//
//  JYBidViewCell.h
//  joyyios
//
//  Created by Ping Yang on 4/25/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYBid.h"

@interface JYBidViewCell : UITableViewCell

+ (CGFloat)cellHeight;

- (void)presentBid:(JYBid *)bid;

@end