//
//  JYBid.h
//  joyyios
//
//  Created by Ping Yang on 5/24/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

typedef NS_ENUM(NSUInteger, JYBidStatus)
{
    JYBidStatusActive = 0,
    JYBidStatusAccepted = 1,
    JYBidStatusRejected = 10,
    JYBidStatusRevoked = 20
};

@interface JYBid : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@property(nonatomic) JYBidStatus  status;
@property(nonatomic) NSUInteger bidId;
@property(nonatomic) NSUInteger orderId;
@property(nonatomic) NSUInteger userId;
@property(nonatomic) NSUInteger price;
@property(nonatomic) NSDate *expireTime;
@property(nonatomic) NSString *note;

@property(nonatomic, readonly) BOOL expired;
@property(nonatomic, readonly) NSString *expireTimeString;
@property(nonatomic, readonly) NSString *priceString;
@property(nonatomic, readonly) UIColor *statusColor;

// Optional properties
@property(nonatomic) NSString *username;
@property(nonatomic) NSUInteger userRatingTotal;
@property(nonatomic) NSUInteger userRatingCount;

@end
