//
//  JYLocationManager.h
//  joyyios
//
//  Created by Andy Wei on 11/2/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@import CoreLocation;

@interface JYLocationManager : NSObject

+ (JYLocationManager *)sharedInstance;

@property (nonatomic) CGFloat presentedIntroductionVersion;
@property (nonatomic) CLLocationCoordinate2D lastCoordinate;
@property (nonatomic) NSString *lastZip;

@end