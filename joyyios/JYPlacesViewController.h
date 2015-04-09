//
//  JYPlacesViewController.h
//  joyyios
//
//  Created by Ping Yang on 4/8/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@import MapKit;

@class JYPlacesViewController;

@protocol JYPlacesViewControllerDelegate <NSObject>

- (void)placesViewController:(JYPlacesViewController *)viewController placemarkSelected:(MKPlacemark *)placemark;

@end

@interface JYPlacesViewController : UIViewController <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property(nonatomic) CLLocationCoordinate2D searchCenter;
@property(nonatomic) UIImage *searchBarImage;
@property(nonatomic, weak) id<JYPlacesViewControllerDelegate> delegate;

@end
