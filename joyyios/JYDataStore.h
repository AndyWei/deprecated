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
@property(nonatomic) NSString *deviceToken;
@property(nonatomic) NSInteger badgeCount;


@end
