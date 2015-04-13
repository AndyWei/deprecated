//
//  JYCompleteOrder.h
//  joyyios
//
//  Created by Ping Yang on 4/12/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYOrder.h"

@interface JYCompleteOrder : JYOrder

@property(nonatomic) NSUInteger orderId;
@property(nonatomic) NSUInteger userId;
@property(nonatomic) NSUInteger winnnerId;
@property(nonatomic) CGFloat finalPrice;
@property(nonatomic) NSDate *createdAt;
@property(nonatomic) NSDate *updatedAt;

@end
