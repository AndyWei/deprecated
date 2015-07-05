//
//  JYInvite.h
//  joyyios
//
//  Created by Ping Yang on 4/9/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@import MapKit;

typedef NS_ENUM(NSUInteger, JYServiceCategory)
{
    JYServiceCategoryNone = 0,
    JYServiceCategoryAssistant = 1,
    JYServiceCategoryEscort = 2,
    JYServiceCategoryMassage = 3,
    JYServiceCategoryPerformer = 4
};

typedef NS_ENUM(NSUInteger, JYInviteStatus)
{
    JYInviteStatusActive = 0,
    JYInviteStatusDealt = 1,
    JYInviteStatusStarted = 2,
    JYInviteStatusFinished = 3,
    JYInviteStatusPaid = 10,
    JYInviteStatusRevoked = 20
};

@interface JYInvite : NSObject

+ (JYInvite *)currentInvite;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (void)clear;
- (NSDictionary *)httpParameters;

// Properties in the create order reqeust
@property(nonatomic) CLLocationDegrees lat;
@property(nonatomic) CLLocationDegrees lon;

@property(nonatomic) NSString *currency;
@property(nonatomic) NSString *country;
@property(nonatomic) NSString *title;
@property(nonatomic) NSString *note;
@property(nonatomic) NSString *city;
@property(nonatomic) NSString *address;

@property(nonatomic) JYServiceCategory category;
@property(nonatomic) NSUInteger price;
@property(nonatomic) NSUInteger startTime;

// Properties not in the create order request
@property(nonatomic) NSUInteger finalPrice;
@property(nonatomic) NSUInteger orderId;
@property(nonatomic) NSUInteger userId;
@property(nonatomic) NSUInteger winnerId;
@property(nonatomic) NSString *winnerName;
@property(nonatomic) JYInviteStatus status;

@property(nonatomic) NSDate *createdAt;
@property(nonatomic) NSDate *updatedAt;
@property(nonatomic) NSDate *finishedAt;

@property(nonatomic) NSMutableArray *bids;
@property(nonatomic) NSMutableArray *comments;

@property(nonatomic, readonly) NSString *categoryName;
@property(nonatomic, readonly) NSString *createTimeString;
@property(nonatomic, readonly) NSString *finalPriceString;
@property(nonatomic, readonly) NSString *finishTimeString;
@property(nonatomic, readonly) NSString *priceString;
@property(nonatomic, readonly) UIColor *bidColor;
@property(nonatomic, readonly) UIColor *paymentStatusColor;
@property(nonatomic, readonly) UIColor *workingStatusColor;

@end
