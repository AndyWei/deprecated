//
//  Order.h
//  joyyios
//
//  Created by Ping Yang on 4/9/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@import MapKit;

@interface JYOrder : NSObject

+ (JYOrder *)currentOrder;
+ (void)deleteCurrentOrder;

- (void)submit;

@property(nonatomic) NSUInteger orderId;
@property(nonatomic) NSUInteger winnnerId;
@property(nonatomic) NSUInteger status;
@property(nonatomic) NSUInteger category;
@property(nonatomic) NSUInteger categoryIndex;
@property(nonatomic) CGFloat price;
@property(nonatomic) CGFloat finalPrice;
@property(nonatomic) CLLocationCoordinate2D startPoint;
@property(nonatomic) CLLocationCoordinate2D endPoint;
@property(nonatomic) NSString *userId;
@property(nonatomic) NSString *currency;
@property(nonatomic) NSString *country;
@property(nonatomic) NSString *descriptionText;
@property(nonatomic) NSString *startAddress;
@property(nonatomic) NSString *endAddress;
@property(nonatomic) NSDate *createdAt;
@property(nonatomic) NSDate *updatedAt;

@end
