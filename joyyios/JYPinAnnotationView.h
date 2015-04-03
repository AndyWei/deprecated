//
//  JYPinAnnotationView.h
//  joyyios
//
//  Created by Ping Yang on 4/2/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <MapKit/MapKit.h>

typedef NS_ENUM(NSUInteger, JYPinAnnotationColor)
{
    JYPinAnnotationColorNone = 0,
    JYPinAnnotationColorBlue,
    JYPinAnnotationColorGreen,
    JYPinAnnotationColorPink
};

@interface JYPinAnnotationView : MKAnnotationView

@property(nonatomic) JYPinAnnotationColor pinColor;

@end
