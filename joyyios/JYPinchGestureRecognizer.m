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

@end

@implementation JYPinchGestureRecognizer

- (id)initWithMapView:(MKMapView *)mapView
{
    if (mapView == nil)
    {
        [NSException raise:NSInvalidArgumentException format:@"mapView cannot be nil."];
    }

    if ((self = [super initWithTarget:self action:@selector(_handlePinchGesture)]))
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
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
    {
        return YES;
    }
    return NO;
}

- (void)_handlePinchGesture
{
    if (self.mapView == nil || [self numberOfTouches] < 2)
    {
        return;
    }

    if (self.state == UIGestureRecognizerStateBegan)
    {
        self.originalAltitude = self.mapView.camera.altitude;
    }
    else
    {
        double scale = (double)self.scale;
        CLLocationDistance altitude = self.originalAltitude / scale;
        altitude = fmax(altitude, 350.f);
        self.mapView.camera.altitude = altitude;
    }
}

@end
