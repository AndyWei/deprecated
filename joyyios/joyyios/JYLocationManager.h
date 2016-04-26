//
//  JYLocationManager.h
//  joyyios
//
//  Created by Ping Yang on 11/2/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@import CoreLocation;

@interface JYLocationManager : NSObject

- (void)start;

@property (nonatomic) NSString *countryCode;
@property (nonatomic) NSString *zip;

@end