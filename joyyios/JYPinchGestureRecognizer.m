//
//  JYPinchGestureRecognizer.m
//  joyyios
//
//  Created by Ping Yang on 4/2/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYPinchGestureRecognizer.h"

@interface JYPinchGestureRecognizer ()

@property(nonatomic, weak) MKMapView *mapView;
@property(nonatomic) CLLocationDistance originalAltitude;
@property(nonatomic) CLLocationCoordinate2D originalCenterCoordinate;

@end

@implementation JYPinchGestureRecognizer

- (instancetype)initWithMapView:(MKMapView *)mapView
{
    if (!mapView)
    {
        [NSException raise:NSInvalidArgumentException format:@"mapView cannot be nil."];
    }

    if ((self = [super initWithTarget:self action:@selector(_handlePinchGesture:)]))
    {
        self.mapView = mapView;
    }

    return self;
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    return NO;
}

- (void)_handlePinchGesture:(JYPinchGestureRecognizer *)sender
{
    if (!sender.mapView || [self numberOfTouches] < 2)
    {
        return;
    }

    if (sender.state == UIGestureRecognizerStateBegan)
    {
        sender.originalAltitude = sender.mapView.camera.altitude;
        sender.originalCenterCoordinate = sender.mapView.centerCoordinate;
    }
    else
    {
        double scale = (double)self.scale;
        CLLocationDistance altitude = sender.originalAltitude / scale;
        altitude = fmax(altitude, 350.f);
        sender.mapView.centerCoordinate = sender.originalCenterCoordinate;
        sender.mapView.camera.altitude = altitude;
    }
}

@end
