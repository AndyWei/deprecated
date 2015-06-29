//
//  JYOrder.h
//  joyyios
//
//  Created by Ping Yang on 4/9/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@import MapKit;

#import "JYServiceCategory.h"

typedef NS_ENUM(NSUInteger, JYOrderStatus)
{
    JYOrderStatusActive = 0,
    JYOrderStatusPending = 1,
    JYOrderStatusOngoing = 2,
    JYOrderStatusFinished = 3,
    JYOrderStatusPaid = 10,
    JYOrderStatusRevoked = 20
};

@interface JYOrder : NSObject

+ (JYOrder *)currentOrder;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (void)clear;
- (NSDictionary *)httpParameters;

// Properties in the create order reqeust
@property(nonatomic) CLLocationDegrees startPointLat;
@property(nonatomic) CLLocationDegrees startPointLon;
@property(nonatomic) CLLocationDegrees endPointLat;
@property(nonatomic) CLLocationDegrees endPointLon;

@property(nonatomic) NSString *currency;
@property(nonatomic) NSString *country;
@property(nonatomic) NSString *title;
@property(nonatomic) NSString *note;
@property(nonatomic) NSString *startCity;
@property(nonatomic) NSString *startAddress;
@property(nonatomic) NSString *endAddress;

@property(nonatomic) NSUInteger category;
@property(nonatomic) NSUInteger price;
@property(nonatomic) NSUInteger startTime;

// Properties not in the create order request
@property(nonatomic) JYServiceCategoryIndex categoryIndex;
@property(nonatomic) NSUInteger finalPrice;
@property(nonatomic) NSUInteger orderId;
@property(nonatomic) NSUInteger userId;
@property(nonatomic) NSUInteger winnerId;
@property(nonatomic) NSString *winnerName;
@property(nonatomic) JYOrderStatus status;

@property(nonatomic) NSDate *createdAt;
@property(nonatomic) NSDate *updatedAt;
@property(nonatomic) NSDate *finishedAt;

@property(nonatomic) NSMutableArray *bids;
@property(nonatomic) NSMutableArray *comments;

@property(nonatomic, readonly) BOOL hasEndAddress;
@property(nonatomic, readonly) NSString *createTimeString;
@property(nonatomic, readonly) NSString *finishTimeString;
@property(nonatomic, readonly) NSString *priceString;
@property(nonatomic, readonly) NSString *finalPriceString;
@property(nonatomic, readonly) UIColor *bidColor;
@property(nonatomic, readonly) UIColor *paymentStatusColor;
@property(nonatomic, readonly) UIColor *workingStatusColor;

@end
