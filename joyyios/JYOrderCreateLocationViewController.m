//
//  JYOrderCreateLocationViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "JYButton.h"
#import "JYOrderCreateFormViewController.h"
#import "JYOrderCreateLocationViewController.h"
#import "JYPinAnnotationView.h"
#import "JYServiceCategory.h"

@interface JYOrderCreateLocationViewController ()
{
    JYPanGestureRecognizer *_panRecognizer;
    JYPinchGestureRecognizer *_pinchRecognizer;
    MKPointAnnotation *_startPoint;
    MKPointAnnotation *_endPoint;
    UIImageView *_startPointView;
    UIImageView *_endPointView;
}

@property(nonatomic) JYMapDashBoardView *dashBoard;
@property(nonatomic) MapEditMode mapEditMode;
@property(nonatomic) MKMapView *mapView;

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
    self.navigationItem.title = [JYServiceCategory names][self.serviceCategoryIndex];

    [self _createMapView];
    [self _createDashBoard];
    self.mapEditMode = MapEditModeStartPoint;
    [self _updateAddress];
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

    _mapView = [[MKMapView alloc] initWithFrame:mapFrame];
    _mapView.delegate = self;
    _mapView.showsUserLocation = YES;
    _mapView.pitchEnabled = NO;
    _mapView.rotateEnabled = NO;

    // To resolve the map center moving while zooming issue, distable default zooming and use our own pintch gesture recognizer
    _mapView.scrollEnabled = YES;
    _mapView.zoomEnabled = NO;

    // _panRecognizer only be used to detect begin and of of pans for hidding and showing self.dashBoard
    _panRecognizer = [[JYPanGestureRecognizer alloc] initWithMapView:_mapView];
    _panRecognizer.delegate = self;
    [_mapView addGestureRecognizer:_panRecognizer];

    _pinchRecognizer = [[JYPinchGestureRecognizer alloc] initWithMapView:_mapView];
    _pinchRecognizer.delegate = self;
    [_mapView addGestureRecognizer:_pinchRecognizer];

    // The _mapView.userlocation hasn't been initiated at this time point, so use the currentLocation in AppDelegate
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D coordinate = appDelegate.currentLocation.coordinate;

    _mapView.camera.altitude = kMapDefaultAltitude;
    _mapView.centerCoordinate = coordinate;

    [self.view addSubview:_mapView];
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

    CLLocation *location = [[CLLocation alloc] initWithLatitude:_mapView.centerCoordinate.latitude longitude:_mapView.centerCoordinate.longitude];
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

- (void)_moveMapToUserLocation
{
    MKCoordinateRegion newRegion = MKCoordinateRegionMakeWithDistance(_mapView.userLocation.location.coordinate, kMapDefaultSpanDistance, kMapDefaultSpanDistance);

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5f
                     animations:^{
                         [weakSelf.mapView setRegion:newRegion animated:YES];
                     }
                     completion:^(BOOL finished) {
                         [weakSelf _updateAddress];
                     }];
}

- (void)_moveMapToPoint:(MKPointAnnotation *)point andEnterMode:(MapEditMode)mode
{
    // Hide startPointView, show startPointAnnotation
    self.mapEditMode = MapEditModeNone;

    CLLocationCoordinate2D newCenter;

    if (point)
    {
        newCenter = point.coordinate;
    }
    else
    {
        newCenter = CLLocationCoordinate2DMake(_mapView.centerCoordinate.latitude + kMapEndPointCenterOffset,
                                               _mapView.centerCoordinate.longitude + kMapEndPointCenterOffset);
    }

    MKCoordinateRegion newRegion = MKCoordinateRegionMakeWithDistance(newCenter, kMapDefaultSpanDistance, kMapDefaultSpanDistance);
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

- (void)_navigateToNextView
{
    UIViewController *viewController = [JYOrderCreateFormViewController new];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)_showStartPointAnnotation:(BOOL)show
{
    if (show)
    {
        if (!_startPoint)
        {
            _startPoint = [MKPointAnnotation new];
            _startPoint.coordinate = _mapView.centerCoordinate;
            _startPoint.title = kAnnotationTitleStart;
            [_mapView addAnnotation:_startPoint];
        }
    }
    else
    {
        if (_startPoint)
        {
            [_mapView removeAnnotation:_startPoint];
            _startPoint = nil;
        }
    }
}

- (void)_showEndPointAnnotation:(BOOL)show
{
    if (show)
    {
        if (!_endPoint)
        {
            _endPoint = [MKPointAnnotation new];
            _endPoint.coordinate = _mapView.centerCoordinate;
            _endPoint.title = kAnnotationTitleEnd;
            [_mapView addAnnotation:_endPoint];
        }
    }
    else
    {
        if (_endPoint)
        {
            [_mapView removeAnnotation:_endPoint];
            _endPoint = nil;
        }
    }
}

- (void)_showStartPointView:(BOOL)show
{
    if (show)
    {
        if (!_startPointView)
        {
            _startPointView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kPinAnnotationWidth, kPinAnnotationHeight)];
            CGFloat y = (CGRectGetHeight(_mapView.frame) - CGRectGetHeight(_startPointView.frame)) / 2;
            _startPointView.center = CGPointMake(CGRectGetMidX(_mapView.frame), y);

            _startPointView.image = [UIImage imageNamed:kImageNamePinBlue];
            [_mapView addSubview:_startPointView];
        }
    }
    else
    {
        if (_startPointView)
        {
            [_startPointView removeFromSuperview];
            _startPointView = nil;
        }
    }
}

- (void)_showEndPointView:(BOOL)show
{
    if (show)
    {
        if (!_endPointView)
        {
            _endPointView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kPinAnnotationWidth, kPinAnnotationHeight)];
            CGFloat y = (CGRectGetHeight(_mapView.frame) - CGRectGetHeight(_endPointView.frame)) / 2;
            _endPointView.center = CGPointMake(CGRectGetMidX(_mapView.frame), y);

            _endPointView.image = [UIImage imageNamed:kImageNamePinPink];
            [_mapView addSubview:_endPointView];
        }
    }
    else
    {
        if (_endPointView)
        {
            [_endPointView removeFromSuperview];
            _endPointView = nil;
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
    if (_endPoint)
    {
        return NO;
    }

    return [self _shouldHaveEndPoint];
}

- (BOOL)_shouldHaveEndPoint
{
    BOOL result = NO;
    switch (self.serviceCategoryIndex)
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
    return (self.mapEditMode == MapEditModeStartPoint && _endPoint);
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
            NSAssert(_startPoint && _endPoint, @"Both startPoint and endPoint annotations should exist");
            [_mapView showAnnotations:@[ _startPoint, _endPoint ] animated:YES];
            break;
        default:
            break;
    }

    _mapEditMode = mode;
    self.dashBoard.mapEditMode = mode;
}

#pragma mark - JYMapDashBoardViewDelegate

- (void)dashBoard:(JYMapDashBoardView *)dashBoard startButtonPressed:(UIButton *)button
{
    if (self.mapEditMode != MapEditModeEndPoint && self.mapEditMode != MapEditModeDone)
    {
        return;
    }

    [self _moveMapToPoint:_startPoint andEnterMode:MapEditModeStartPoint];
}

- (void)dashBoard:(JYMapDashBoardView *)dashBoard endButtonPressed:(UIButton *)button
{
    if (self.mapEditMode != MapEditModeDone)
    {
        return;
    }

    [self _moveMapToPoint:_endPoint andEnterMode:MapEditModeEndPoint];
}

- (void)dashBoard:(JYMapDashBoardView *)dashBoard submitButtonPressed:(UIButton *)button
{
    switch (self.mapEditMode)
    {
        case MapEditModeStartPoint:
            if ([self _shouldEditEndPoint])
            {
                [self _moveMapToPoint:_endPoint andEnterMode:MapEditModeEndPoint];
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
@end
