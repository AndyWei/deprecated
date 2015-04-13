//
//  JYOrder.h
//  joyyios
//
//  Created by Ping Yang on 4/9/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@import MapKit;

@interface JYOrder : NSObject

+ (JYOrder *)currentOrder;

- (void)clear;
- (NSDictionary *)httpParameters;

// Properties in the create order reqeust
@property(nonatomic) CGFloat price;

@property(nonatomic) CLLocationDegrees startPointLat;
@property(nonatomic) CLLocationDegrees startPointLon;
@property(nonatomic) CLLocationDegrees endPointLat;
@property(nonatomic) CLLocationDegrees endPointLon;

@property(nonatomic) NSString *currency;
@property(nonatomic) NSString *country;
@property(nonatomic) NSString *title;
@property(nonatomic) NSString *note;
@property(nonatomic) NSString *startAddress;
@property(nonatomic) NSString *endAddress;

@property(nonatomic) NSUInteger category;
@property(nonatomic) NSUInteger startTime;

// Properties not in the create order reqeust
@property(nonatomic) CGFloat finalPrice;

@property(nonatomic) NSUInteger categoryIndex;
@property(nonatomic) NSUInteger orderId;
@property(nonatomic) NSUInteger userId;
@property(nonatomic) NSUInteger winnnerId;
@property(nonatomic) NSUInteger status;

@property(nonatomic) NSDate *createdAt;
@property(nonatomic) NSDate *updatedAt;

@end
