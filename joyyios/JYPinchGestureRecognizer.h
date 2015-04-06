//
//  JYPinchGestureRecognizer.h
//  joyyios
//
//  Created by Ping Yang on 4/2/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface JYPinchGestureRecognizer : UIPinchGestureRecognizer

- (instancetype)initWithMapView:(MKMapView *)mapView;

@end
