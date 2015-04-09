//
//  JYOrderCreateLocationViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "JYButton.h"
#import "JYOrder.h"
#import "JYOrderCreateFormViewController.h"
#import "JYOrderCreateLocationViewController.h"
#import "JYPinAnnotationView.h"
#import "JYServiceCategory.h"

@interface JYOrderCreateLocationViewController ()

@property(nonatomic) BOOL mapNeedsPadding;
@property(nonatomic) CLLocationCoordinate2D userSelectedMapCenter;
@property(nonatomic) JYMapDashBoardView *dashBoard;
@property(nonatomic) JYPanGestureRecognizer *panRecognizer;
@property(nonatomic) JYPinchGestureRecognizer *pinchRecognizer;
@property(nonatomic) MapEditMode mapEditMode;
@property(nonatomic) MKMapView *mapView;
@property(nonatomic) MKPointAnnotation *startPoint;
@property(nonatomic) MKPointAnnotation *endPoint;
@property(nonatomic) UIImageView *startPointView;
@property(nonatomic) UIImageView *endPointView;

@end

static NSString *reuseId = @"pin";

@implementation JYOrderCreateLocationViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        _mapEditMode = MapEditModeNone;
    }
    return self;
}

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    NSUInteger categoryIndex = [JYOrder currentOrder].categoryIndex;
    self.navigationItem.title = [JYServiceCategory names][categoryIndex];

    [self _createMapView];
    [self _createDashBoard];
    self.mapEditMode = MapEditModeStartPoint;
    [self _updateAddress];
}

- (void)viewDidAppear:(BOOL)animated
{
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
    // Dispose of any resources that can be recreated.
}

- (void)_createMapView
{
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    CGFloat topMargin = CGRectGetHeight(statusBarFrame) + CGRectGetHeight(self.navigationController.navigationBar.frame);
    CGRect mapFrame = CGRectMake(0, topMargin, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - topMargin);

    self.mapView = [[MKMapView alloc] initWithFrame:mapFrame];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.mapView.pitchEnabled = NO;
    self.mapView.rotateEnabled = NO;

    // To resolve the map center moving while zooming issue, distable default zooming and use our own pintch gesture recognizer
    self.mapView.scrollEnabled = YES;
    self.mapView.zoomEnabled = NO;

    // The panRecognizer only be used to detect begin and of of pans for hidding and showing self.dashBoard
    self.panRecognizer = [[JYPanGestureRecognizer alloc] init];
    self.panRecognizer.delegate = self;
    [self.mapView addGestureRecognizer:self.panRecognizer];

    self.pinchRecognizer = [[JYPinchGestureRecognizer alloc] initWithMapView:self.mapView];
    self.pinchRecognizer.delegate = self;
    [self.mapView addGestureRecognizer:self.pinchRecognizer];

    // The self.mapView.userlocation hasn't been initiated at this time point, so use the currentLocation in AppDelegate
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.userSelectedMapCenter = appDelegate.currentLocation.coordinate;

    self.mapView.camera.altitude = kMapDefaultAltitude;
    self.mapView.centerCoordinate = self.userSelectedMapCenter;

    [self.view addSubview:self.mapView];
}

- (void)_createDashBoard
{
    CGFloat y = CGRectGetHeight(self.view.frame) - kMapDashBoardHeight;
    CGRect frame = CGRectMake(0, y, CGRectGetWidth(self.view.frame), kMapDashBoardHeight);

    JYMapDashBoardStyle style = ([self _shouldHaveEndPoint]) ? JYMapDashBoardStyleStartAndEnd : JYMapDashBoardStyleStartOnly;
    self.dashBoard = [[JYMapDashBoardView alloc] initWithFrame:frame withStyle:style];
    self.dashBoard.delegate = self;

    [self.view addSubview:self.dashBoard];
}

- (void)_updateAddress
{
    if (self.mapEditMode != MapEditModeStartPoint && self.mapEditMode != MapEditModeEndPoint)
    {
        return;
    }

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
                           CLPlacemark *placemark = [placemarks objectAtIndex:0];
                           NSString *locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
                           NSString *address = [[NSString alloc] initWithString:locatedAt];

                           if (weakSelf.mapEditMode == MapEditModeStartPoint)
                           {
                               weakSelf.dashBoard.startButton.textLabel.text = address;
                           }
                           else if (weakSelf.mapEditMode == MapEditModeEndPoint)
                           {
                               weakSelf.dashBoard.endButton.textLabel.text = address;
                           }
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

- (void)_moveMapToPoint:(CLLocationCoordinate2D)center andEnterMode:(MapEditMode)mode
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
                             weakSelf.mapEditMode = mode;
                         }
                     }];
}

- (void)_moveMapToPointAnnotation:(MKPointAnnotation *)pointAnnotation andEnterMode:(MapEditMode)mode
{
    // Hide startPointView, show startPointAnnotation
    self.mapEditMode = MapEditModeNone;

    CLLocationCoordinate2D newCenter;

    if (pointAnnotation)
    {
        newCenter = pointAnnotation.coordinate;
    }
    else
    {
        newCenter = CLLocationCoordinate2DMake(self.mapView.centerCoordinate.latitude + kMapEndPointCenterOffset,
                                               self.mapView.centerCoordinate.longitude + kMapEndPointCenterOffset);
    }

    [self _moveMapToPoint:newCenter andEnterMode:(MapEditMode)mode];
}

- (void)_navigateToNextView
{
    JYOrder *currentOrder = [JYOrder currentOrder];
    currentOrder.startPoint = self.startPoint.coordinate;
    currentOrder.startAddress = self.dashBoard.startButton.textLabel.text;
    if (self.endPoint)
    {
        currentOrder.endPoint = self.startPoint.coordinate;
        currentOrder.endAddress = self.dashBoard.endButton.textLabel.text;
    }

    UIViewController *viewController = [JYOrderCreateFormViewController new];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)_showStartPointAnnotation:(BOOL)show
{
    if (show)
    {
        if (!self.startPoint)
        {
            self.startPoint = [MKPointAnnotation new];
            self.startPoint.coordinate = self.mapView.centerCoordinate;
            self.startPoint.title = kAnnotationTitleStart;
            [self.mapView addAnnotation:self.startPoint];
        }
    }
    else
    {
        if (self.startPoint)
        {
            [self.mapView removeAnnotation:self.startPoint];
            self.startPoint = nil;
        }
    }
}

- (void)_showEndPointAnnotation:(BOOL)show
{
    if (show)
    {
        if (!self.endPoint)
        {
            self.endPoint = [MKPointAnnotation new];
            self.endPoint.coordinate = self.mapView.centerCoordinate;
            self.endPoint.title = kAnnotationTitleEnd;
            [self.mapView addAnnotation:self.endPoint];
        }
    }
    else
    {
        if (self.endPoint)
        {
            [self.mapView removeAnnotation:self.endPoint];
            self.endPoint = nil;
        }
    }
}

- (void)_showStartPointView:(BOOL)show
{
    if (show)
    {
        if (!self.startPointView)
        {
            self.startPointView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kPinAnnotationWidth, kPinAnnotationHeight)];
            CGFloat y = (CGRectGetHeight(self.mapView.frame) - CGRectGetHeight(self.startPointView.frame)) / 2;
            self.startPointView.center = CGPointMake(CGRectGetMidX(self.mapView.frame), y);

            self.startPointView.image = [UIImage imageNamed:kImageNamePinBlue];
            [self.mapView addSubview:self.startPointView];
        }
    }
    else
    {
        if (self.startPointView)
        {
            [self.startPointView removeFromSuperview];
            self.startPointView = nil;
        }
    }
}

- (void)_showEndPointView:(BOOL)show
{
    if (show)
    {
        if (!self.endPointView)
        {
            self.endPointView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kPinAnnotationWidth, kPinAnnotationHeight)];
            CGFloat y = (CGRectGetHeight(self.mapView.frame) - CGRectGetHeight(self.endPointView.frame)) / 2;
            self.endPointView.center = CGPointMake(CGRectGetMidX(self.mapView.frame), y);

            self.endPointView.image = [UIImage imageNamed:kImageNamePinPink];
            [self.mapView addSubview:self.endPointView];
        }
    }
    else
    {
        if (self.endPointView)
        {
            [self.endPointView removeFromSuperview];
            self.endPointView = nil;
        }
    }
}

- (BOOL)_shouldEditEndPoint
{
    if (self.mapEditMode != MapEditModeStartPoint)
    {
        return NO;
    }

    // Already edited end point previously
    if (self.endPoint)
    {
        return NO;
    }

    return [self _shouldHaveEndPoint];
}

- (BOOL)_shouldHaveEndPoint
{
    BOOL result = NO;
    NSUInteger categoryIndex = [JYOrder currentOrder].categoryIndex;
    switch (categoryIndex)
    {
        case JYServiceCategoryIndexCleaning:
        case JYServiceCategoryIndexGardener:
        case JYServiceCategoryIndexHandyman:
        case JYServiceCategoryIndexPersonalAssistant:
        case JYServiceCategoryIndexPlumbing:
        case JYServiceCategoryIndexRoadsideAssistance:
        case JYServiceCategoryIndexOther:
            // do nothing
            break;
        case JYServiceCategoryIndexDelivery:
        case JYServiceCategoryIndexMoving:
        case JYServiceCategoryIndexRide:
            result = YES;
            break;
        default:
            break;
    }
    return result;
}

- (BOOL)_shouldJumpToDone
{
    return (self.mapEditMode == MapEditModeStartPoint && self.endPoint);
}

- (void)setMapEditMode:(MapEditMode)mode
{
    if (_mapEditMode == mode)
    {
        return;
    }

    // Finish current mode
    switch (_mapEditMode)
    {
        case MapEditModeStartPoint:
            [self _showStartPointView:NO];
            [self _showStartPointAnnotation:YES];
            break;
        case MapEditModeEndPoint:
            [self _showEndPointView:NO];
            break;
        default:
            break;
    }

    // Enter new mode
    switch (mode)
    {
        case MapEditModeStartPoint:
            [self _showStartPointView:YES];
            [self _showStartPointAnnotation:NO];
            break;
        case MapEditModeEndPoint:
            [self _showEndPointView:YES];
            [self _showEndPointAnnotation:NO];
            break;
        case MapEditModeDone:
            [self _showEndPointAnnotation:YES];
            [self _presentAnnotations];
            break;
        default:
            break;
    }

    _mapEditMode = mode;
    self.dashBoard.mapEditMode = mode;
}

- (void)_presentAnnotations
{
    NSAssert(self.startPoint && self.endPoint, @"Both startPoint and endPoint annotations should exist");

    self.mapNeedsPadding = YES;
    [self.mapView showAnnotations:@[ self.startPoint, self.endPoint ] animated:YES];
}

- (void)_presentPlacesViewController
{
    // Avoid map moving when user press the cancel button in the JYPlacesViewController
    self.userSelectedMapCenter = self.mapView.centerCoordinate;

    JYPlacesViewController *placesViewController = [JYPlacesViewController new];
    placesViewController.delegate = self;

    NSString *imageName = (self.mapEditMode == MapEditModeStartPoint)? kImageNamePinBlue: kImageNamePinPink;
    placesViewController.searchBarImage = [UIImage imageNamed:imageName];
    placesViewController.searchCenter = self.mapView.centerCoordinate;

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:placesViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - JYMapDashBoardViewDelegate

- (void)dashBoard:(JYMapDashBoardView *)dashBoard startButtonPressed:(UIButton *)button
{
    if (self.mapEditMode == MapEditModeStartPoint)
    {
        [self _presentPlacesViewController];
    }
    else
    {
        [self _moveMapToPointAnnotation:self.startPoint andEnterMode:MapEditModeStartPoint];
    }
}

- (void)dashBoard:(JYMapDashBoardView *)dashBoard endButtonPressed:(UIButton *)button
{
    if (self.mapEditMode == MapEditModeEndPoint)
    {
        [self _presentPlacesViewController];
    }
    else
    {
        [self _moveMapToPointAnnotation:self.endPoint andEnterMode:MapEditModeEndPoint];
    }
}

- (void)dashBoard:(JYMapDashBoardView *)dashBoard submitButtonPressed:(UIButton *)button
{
    switch (self.mapEditMode)
    {
        case MapEditModeStartPoint:
            if ([self _shouldEditEndPoint])
            {
                [self _moveMapToPointAnnotation:self.endPoint andEnterMode:MapEditModeEndPoint];
            }
            else if ([self _shouldJumpToDone])
            {
                // Make sure startPointAnnotation is set
                self.mapEditMode = MapEditModeNone;
                self.mapEditMode = MapEditModeDone;
            }
            else
            {
                [self _navigateToNextView];
            }
            break;
        case MapEditModeEndPoint:
            self.mapEditMode = MapEditModeDone;
            break;
        case MapEditModeDone:
            [self _navigateToNextView];
            break;
        default:
            break;
    }
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

        // When _presentAnnotations was called, must make sure both of the annotations aren't under the dashBoard
        // Add a bottom edge inset is the solution

        CGFloat submitButtonHeight = CGRectGetHeight(self.dashBoard.submitButton.frame);
        CGFloat startButtonHeight = CGRectGetHeight(self.dashBoard.startButton.frame);
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, 0, submitButtonHeight + startButtonHeight, 0);

        [self.mapView setVisibleMapRect:self.mapView.visibleMapRect edgePadding:edgeInsets animated:YES];
    }
    else
    {
        [self.mapView setVisibleMapRect:self.mapView.visibleMapRect edgePadding:UIEdgeInsetsMake(0, 0, 0, 0) animated:NO];
    }
}

#pragma mark - JYPanGestureRecognizerDelegate

- (void)panGestureBegin
{
    self.dashBoard.hidden = YES;
}

- (void)panGestureEnd
{
    self.dashBoard.hidden = NO;
    [self _updateAddress];
}

#pragma mark - JYPinchGestureRecognizerDelegate

- (void)pinchGestureBegin
{
    self.dashBoard.hidden = YES;
}

- (void)pinchGestureEnd
{
    self.dashBoard.hidden = NO;
    [self _updateAddress];
}

#pragma mark - JYPlacesViewControllerDelegate

- (void)placesViewController:(JYPlacesViewController *)viewController placemarkSelected:(MKPlacemark *)placemark
{
    self.userSelectedMapCenter = placemark? placemark.coordinate: self.mapView.userLocation.location.coordinate;
}

@end
