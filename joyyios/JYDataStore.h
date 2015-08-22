//
//  JYDataStore.h
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//


@import CoreLocation;

@interface JYDataStore : NSObject

+ (JYDataStore *)sharedInstance;

@property(nonatomic) CGFloat presentedIntroductionVersion;
@property(nonatomic) CLLocationCoordinate2D lastCoordinate;
@property(nonatomic) NSString *lastCellId;
@property(nonatomic) NSDictionary *userCredential;
@property(nonatomic) NSTimeInterval tokenExpireTime;
@property(nonatomic) NSString *deviceToken;
@property(nonatomic) NSString *defaultCardNumber; // the last 4 digits of default credit card
@property(nonatomic) NSString *defaultCustomerId; // the stripe customer id of default credit card
@property(nonatomic) NSInteger badgeCount;


@end
