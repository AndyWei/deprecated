//
//  JYMapViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "JYButton.h"
#import "JYInvite.h"
#import "JYMapViewController.h"
#import "JYPinAnnotationView.h"
#import "JYSelectionViewController.h"

@interface JYMapViewController ()

@property(nonatomic) CLLocationCoordinate2D userSelectedMapCenter;
@property(nonatomic) MKPointAnnotation *point;

@property(nonatomic, weak) UIImageView *pointView;
@property(nonatomic, weak) JYButton *addressButton;
@property(nonatomic, weak) JYButton *submitButton;
@property(nonatomic, weak) JYMapDashBoardView *dashBoard;
@property(nonatomic, weak) MKMapView *mapView;

// for pinch gesture
@property(nonatomic) CLLocationDistance originalAltitude;
@property(nonatomic) CLLocationCoordinate2D originalCenterCoordinate;

@end

static NSString *reuseId = @"pin";

@implementation JYMapViewController

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"JOYY";

    UIImage *menu = [UIImage imageNamed:@"menu"];
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:menu style:UIBarButtonItemStylePlain target:self action:@selector(_menu)];
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    negativeSpacer.width = -15;

    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, menuButton, nil];

    [self _createMapView];
    [self _createAddressButton];
    [self _createPointView];
    [self _createSubmitButton];
    [self _createDashBoard];
    [self _updateAddress];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

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

- (void)_createAddressButton
{
    CGFloat width = CGRectGetWidth(self.view.frame) - kMarginLeft - kMarginRight;
    CGRect frame = CGRectMake(kMarginLeft, 15, width, 50);
    JYButton *button = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleImageWithTitle shouldMaskImage:NO];

    button.backgroundColor = JoyyWhite;
    button.contentColor = FlatBlack;
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 0);
    button.cornerRadius = kButtonCornerRadius;
    button.foregroundAnimateToColor = FlatWhite;
    button.foregroundColor = JoyyWhite;
    button.imageView.image = [UIImage imageNamed:@"search"];
    button.textLabel.font = [UIFont systemFontOfSize:18];
    button.textLabel.adjustsFontSizeToFitWidth = YES;
    button.textLabel.textAlignment = NSTextAlignmentCenter;
    [button addTarget:self action:@selector(_addressButtonPressed) forControlEvents:UIControlEventTouchUpInside];

    self.addressButton = button;
    [self.mapView addSubview:self.addressButton];
}

- (void)_createPointView
{
    UIImageView *pointView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kPinAnnotationWidth, kPinAnnotationHeight)];
    CGFloat y = (CGRectGetHeight(self.mapView.frame) - CGRectGetHeight(pointView.frame)) / 2;
    pointView.center = CGPointMake(CGRectGetMidX(self.mapView.frame), y);
    pointView.image = [UIImage imageNamed:kImageNamePinBlue];

    self.pointView = pointView;
    [self.mapView addSubview:self.pointView];
}

- (void)_createSubmitButton
{
    CGFloat y = CGRectGetMinY(self.pointView.frame) - 40;
    CGRect frame = CGRectMake(0, y, 220, 40);
    JYButton *button = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleTitle shouldMaskImage:NO];
    button.centerX = self.mapView.centerX;

    button.backgroundColor = JoyyWhite;
    button.borderColor = FlatGray;
    button.borderWidth = 0.5;
    button.cornerRadius = 20;
    button.contentColor = JoyyBlue;
    button.contentAnimateToColor = JoyyWhite;
    button.foregroundColor = JoyyWhite;
    button.foregroundAnimateToColor = JoyyBlue;
    button.textLabel.text = NSLocalizedString(@"Set Service Location >>", nil);
    button.textLabel.font = [UIFont systemFontOfSize:20];
    [button addTarget:self action:@selector(_submitButtonPressed) forControlEvents:UIControlEventTouchUpInside];

    self.submitButton = button;
    [self.mapView addSubview:self.submitButton];
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

- (void)_addressButtonPressed
{
    [self _presentPlacesViewController];
}

- (void)_submitButtonPressed
{
    self.userSelectedMapCenter = self.mapView.centerCoordinate;
    [self _presentSelectionViewController];
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

                           weakSelf.addressButton.textLabel.text = address;
                           [JYInvite currentInvite].address = address;
                           [JYInvite currentInvite].city = placemark.locality;
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

- (void)_presentSelectionViewController
{
    JYInvite *currentInvite = [JYInvite currentInvite];

    if (!currentInvite.address)
    {
        NSLog(@"address not set");
        return;
    }

    currentInvite.lat = self.mapView.centerCoordinate.latitude;
    currentInvite.lon = self.mapView.centerCoordinate.longitude;

    if (currentInvite.lat == 0.0 && currentInvite.lon == 0.0)
    {
        NSLog(@"point not set");
        return;
    }

    UIViewController *viewController = [JYSelectionViewController new];
    [self.navigationController pushViewController:viewController animated:YES];
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

- (void)didPressLocateButton
{
    [self _moveMapToUserLocation];
}

- (void)didSelectSegment:(NSInteger)index
{
    [JYInvite currentInvite].category = index + 1;
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
