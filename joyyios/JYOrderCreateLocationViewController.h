//
//  JYOrderLocationCreateViewController.h
//  joyyios
//
//  Created by Ping Yang on 4/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYMapDashBoardView.h"
#import "JYPanGestureRecognizer.h"
#import "JYPinchGestureRecognizer.h"
#import "JYPlacesViewController.h"
#import "JYServiceCategory.h"

@import MapKit;

@interface JYOrderCreateLocationViewController : UIViewController <JYMapDashBoardViewDelegate, JYPanGestureRecognizerDelegate, JYPinchGestureRecognizerDelegate, JYPlacesViewControllerDelegate, MKMapViewDelegate>

@end
