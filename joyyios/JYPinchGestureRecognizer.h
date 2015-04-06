//
//  JYPinchGestureRecognizer.h
//  joyyios
//
//  Created by Ping Yang on 4/2/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <MapKit/MapKit.h>

@protocol JYPinchGestureRecognizerDelegate <NSObject>

@optional
- (void)pinchGestureBegin;
- (void)pinchGestureEnd;

@end


@interface JYPinchGestureRecognizer : UIPinchGestureRecognizer

- (instancetype)initWithMapView:(MKMapView *)mapView;

@property(nonatomic, weak) id<JYPinchGestureRecognizerDelegate> delegate;

@end
