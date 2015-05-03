//
//  AppDelegate.h
//  joyyor
//
//  Created by Ping Yang on 5/2/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@import CoreLocation;

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property(nonatomic) UIWindow *window;
@property(nonatomic) CLLocationManager *locationManager;
@property(nonatomic) CLLocation *currentLocation;

@end
