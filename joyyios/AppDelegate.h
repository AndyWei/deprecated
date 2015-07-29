//
//  AppDelegate.h
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@import CoreLocation;

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property(nonatomic) UIWindow *window;
@property(nonatomic) CLLocationManager *locationManager;
@property(nonatomic) CLLocationCoordinate2D currentCoordinate;
@property(nonatomic) NSString *cellId;

@end
