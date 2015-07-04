//
//  JYOrderMapViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "JYButton.h"
#import "JYOrder.h"
#import "JYOrderDetailsViewController.h"
#import "JYOrderMapViewController.h"
#import "JYPinAnnotationView.h"

@interface JYOrderMapViewController ()

@property(nonatomic) BOOL mapNeedsPadding;
@property(nonatomic) CLLocationCoordinate2D userSelectedMapCenter;
@property(nonatomic) MKPointAnnotation *point;
@property(nonatomic) UIImageView *pointView;

@property(nonatomic, weak) JYMapDashBoardView *dashBoard;
@property(nonatomic, weak) MKMapView *mapView;

// for pinch gesture
@property(nonatomic) CLLocationDistance originalAltitude;
@property(nonatomic) CLLocationCoordinate2D originalCenterCoordinate;

@end

static NSString *reuseId = @"pin";

@implementation JYOrderMapViewController

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithTitle:@"JOYY" style:UIBarButtonItemStylePlain target:self action:@selector(_menu)];
    self.navigationItem.leftBarButtonItem = menuButton;

    [self _createMapView];
    [self _createDashBoard];
    [self _enterMapEditMode:YES];
    [self _updateAddress];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self _enterMapEditMode:YES];

    if (self.userSelectedMapCenter.latitude == self.mapView.centerCoordinate.latitude &&
        self.userSelectedMapCenter.longitude == self.mapView.centerCoordinate.longitude)
    {
        return;
    }
    [self _moveMapToPoint:self.userSelectedMapCenter];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)_menu
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidPressMenuButton object:nil];
}

- (void)_createMapView
{
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    CGFloat topMargin = CGRectGetHeight(statusBarFrame) + CGRectGetHeight(self.navigationController.navigationBar.frame);
    CGRect mapFrame = CGRectMake(0, topMargin, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - topMargin);

    MKMapView *mapView = [[MKMapView alloc] initWithFrame:mapFrame];
    mapView.delegate = self;
    mapView.showsUserLocation = YES;
    mapView.pitchEnabled = NO;
    mapView.rotateEnabled = NO;

    // To resolve the map center moving while zooming issue, distable default zooming and use our own pintch gesture recognizer
    mapView.scrollEnabled = YES;
    mapView.zoomEnabled = NO;

    // The panRecognizer only be used to detect begin and of of pans for hidding and showing self.dashBoard
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePanGesture:)];
    panRecognizer.delegate = self;
    [mapView addGestureRecognizer:panRecognizer];

    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePinchGesture:)];
    pinchRecognizer.delegate = self;
    [mapView addGestureRecognizer:pinchRecognizer];

    // The mapView.userlocation hasn't been initiated at this time point, so use the currentLocation in AppDelegate
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.userSelectedMapCenter = appDelegate.currentCoordinate;

    mapView.camera.altitude = kMapDefaultAltitude;
    mapView.centerCoordinate = self.userSelectedMapCenter;

    self.mapView = mapView;
    [self.view addSubview:self.mapView];
}

- (void)_createDashBoard
{
    CGFloat y = CGRectGetHeight(self.view.frame) - kMapDashBoardHeight;
    CGRect frame = CGRectMake(0, y, CGRectGetWidth(self.view.frame), kMapDashBoardHeight);

    JYMapDashBoardView *dashBoard = [[JYMapDashBoardView alloc] initWithFrame:frame];
    dashBoard.delegate = self;

    self.dashBoard = dashBoard;
    [self.view addSubview:self.dashBoard];
}

- (void)_handlePanGesture:(UIPanGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        self.dashBoard.hidden = YES;
    }
    else if (sender.state == UIGestureRecognizerStateChanged)
    {
        // Do nothing. The mapview has scroll enabled and will handle scrolling by itself.
    }
    else
    {
        self.dashBoard.hidden = NO;
        [self _updateAddress];
    }
}

- (void)_handlePinchGesture:(UIPinchGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        self.originalAltitude = self.mapView.camera.altitude;
        self.originalCenterCoordinate = self.mapView.centerCoordinate;
        self.dashBoard.hidden = YES;
    }
    else if (sender.state == UIGestureRecognizerStateChanged)
    {
        CLLocationDistance altitude = self.originalAltitude / sender.scale;
        altitude = fmax(altitude, 350.f);
        self.mapView.centerCoordinate = self.originalCenterCoordinate;
        self.mapView.camera.altitude = altitude;
    }
    else
    {
        self.dashBoard.hidden = NO;
        [self _updateAddress];
    }
}

- (void)_updateAddress
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:self.mapView.centerCoordinate.latitude longitude:self.mapView.centerCoordinate.longitude];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    __weak typeof(self) weakSelf = self;
    [geocoder reverseGeocodeLocation:location
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       if (error)
                       {
                           NSLog(@"Geocode failed with error %@", error);
                       }
                       else
                       {
                           CLPlacemark *placemark = [placemarks lastObject];

                           NSString *address = [NSString stringWithFormat:@"%@ %@, %@, %@ %@",
                                                placemark.subThoroughfare,
                                                placemark.thoroughfare,
                                                placemark.locality,
                                                placemark.administrativeArea,
                                                placemark.postalCode];

                           weakSelf.dashBoard.addressButton.textLabel.text = address;
                           [JYOrder currentOrder].address = address;
                           [JYOrder currentOrder].city = placemark.locality;
                       }
                   }];
}

- (void)_moveMapToPoint:(CLLocationCoordinate2D)center
{
    MKCoordinateRegion newRegion = MKCoordinateRegionMakeWithDistance(center, kMapDefaultSpanDistance, kMapDefaultSpanDistance);
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5f
                     animations:^{
                         [weakSelf.mapView setRegion:newRegion animated:YES];
                     }
                     completion:^(BOOL finished) {
                         if (finished)
                         {
                             [weakSelf _updateAddress];
                         }
                     }];
}

- (void)_moveMapToUserLocation
{
    [self _moveMapToPoint:self.mapView.userLocation.location.coordinate];
}

- (void)_navigateToNextView
{
    JYOrder *currentOrder = [JYOrder currentOrder];

    if (!currentOrder.address)
    {
        NSLog(@"address not set");
        return;
    }

    currentOrder.lat = self.point.coordinate.latitude;
    currentOrder.lon = self.point.coordinate.longitude;

    if (currentOrder.lat == 0.0 && currentOrder.lon == 0.0)
    {
        NSLog(@"point not set");
        return;
    }

    UIViewController *viewController = [JYOrderDetailsViewController new];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)_showPointAnnotation:(BOOL)show
{
    if (show)
    {
        if (!self.point)
        {
            self.point = [MKPointAnnotation new];
            self.point.coordinate = self.mapView.centerCoordinate;
            self.point.title = kAnnotationTitleStart;
            [self.mapView addAnnotation:self.point];
        }
    }
    else
    {
        if (self.point)
        {
            [self.mapView removeAnnotation:self.point];
            self.point = nil;
        }
    }
}

- (void)_showPointView:(BOOL)show
{
    if (show)
    {
        if (!self.pointView)
        {
            self.pointView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kPinAnnotationWidth, kPinAnnotationHeight)];
            CGFloat y = (CGRectGetHeight(self.mapView.frame) - CGRectGetHeight(self.pointView.frame)) / 2;
            self.pointView.center = CGPointMake(CGRectGetMidX(self.mapView.frame), y);

            self.pointView.image = [UIImage imageNamed:kImageNamePinBlue];
            [self.mapView addSubview:self.pointView];
        }
    }
    else
    {
        if (self.pointView)
        {
            [self.pointView removeFromSuperview];
            self.pointView = nil;
        }
    }
}

- (void)_enterMapEditMode:(BOOL)edit
{
    [self _showPointView:edit];
    [self _showPointAnnotation:!edit];
    self.userSelectedMapCenter = self.mapView.centerCoordinate;
}

- (void)_presentPlacesViewController
{
    // Avoid map moving when user press the cancel button in the JYPlacesViewController
    self.userSelectedMapCenter = self.mapView.centerCoordinate;

    JYPlacesViewController *placesViewController = [JYPlacesViewController new];
    placesViewController.delegate = self;

    NSString *imageName = kImageNamePinBlue;
    placesViewController.searchBarImage = [UIImage imageNamed:imageName];
    placesViewController.searchCenter = self.mapView.centerCoordinate;

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:placesViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - JYMapDashBoardViewDelegate

- (void)dashBoard:(JYMapDashBoardView *)dashBoard addressButtonPressed:(UIButton *)button
{
    [self _presentPlacesViewController];
}

- (void)dashBoard:(JYMapDashBoardView *)dashBoard submitButtonPressed:(UIButton *)button
{
    [self _enterMapEditMode:NO];
    [self _navigateToNextView];
}

- (void)dashBoard:(JYMapDashBoardView *)dashBoard locateButtonPressed:(UIControl *)button
{
    [self _moveMapToUserLocation];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        return nil; // For user location annotation, return nil so map view shows default view (blue dot).
    }

    JYPinAnnotationView *pinView = (JYPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseId];
    if ([annotation.title isEqualToString:kAnnotationTitleStart] || [annotation.title isEqualToString:kAnnotationTitleEnd])
    {
        if (!pinView)
        {
            pinView = [[JYPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseId];
            pinView.canShowCallout = NO;
        }
        else
        {
            pinView.annotation = annotation;
        }
        pinView.pinColor = [kAnnotationTitleStart isEqualToString:annotation.title] ? JYPinAnnotationColorBlue : JYPinAnnotationColorPink;
    }
    return pinView;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (self.mapNeedsPadding)
    {
        self.mapNeedsPadding = NO;

        // When _presentAnnotations was called, must make sure the point annotations not under the dashBoard
        // Add a bottom edge inset is the solution

        CGFloat submitButtonHeight = CGRectGetHeight(self.dashBoard.submitButton.frame);
        CGFloat startButtonHeight = CGRectGetHeight(self.dashBoard.addressButton.frame);
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, 0, submitButtonHeight + startButtonHeight, 0);

        [self.mapView setVisibleMapRect:self.mapView.visibleMapRect edgePadding:edgeInsets animated:YES];
    }
    else
    {
        [self.mapView setVisibleMapRect:self.mapView.visibleMapRect edgePadding:UIEdgeInsetsMake(0, 0, 0, 0) animated:NO];
    }
}

#pragma mark - JYPlacesViewControllerDelegate

- (void)placesViewController:(JYPlacesViewController *)viewController placemarkSelected:(MKPlacemark *)placemark
{
    self.userSelectedMapCenter = placemark? placemark.coordinate: self.mapView.userLocation.location.coordinate;
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

@end
