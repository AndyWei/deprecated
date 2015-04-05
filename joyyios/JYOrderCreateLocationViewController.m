//
//  JYOrderCreateLocationViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "JYOrderCreateFormViewController.h"
#import "JYOrderCreateLocationViewController.h"
#import "JYPinAnnotationView.h"
#import "JYPinchGestureRecognizer.h"
#import "JYPinchGestureRecognizer.h"
#import "JYServiceCategory.h"
#import "MRoundedButton.h"

@interface JYOrderCreateLocationViewController ()
{
    JYMapDashBoardView *_dashBoard;
    JYPinchGestureRecognizer *_pintchRecognizer;
    MKMapView *_mapView;
    MKPointAnnotation *_startPoint;
    MKPointAnnotation *_endPoint;
    UIImageView *_startPointView;
    UIImageView *_endPointView;
}

@property(nonatomic) MapEditMode mapEditMode;

@end

static NSString *reuseId = @"pin";

@implementation JYOrderCreateLocationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
            [self _showEndPointAnnotation:YES];
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
        case MapEditModeNone:
            [self _showStartPointView:NO];
            [self _showEndPointView:NO];
            [self _showStartPointAnnotation:NO];
            [self _showEndPointAnnotation:NO];
            break;
        default:
            break;
    }

    _mapEditMode = mode;
    _dashBoard.mapEditMode = mode;
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

    _pintchRecognizer = [[JYPinchGestureRecognizer alloc] initWithMapView:_mapView];
    [_mapView addGestureRecognizer:_pintchRecognizer];

    // The _mapView.userlocation hasn't been initiated at this time point, so use the currentLocation in AppDelegate
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D coordinate = appDelegate.currentLocation.coordinate;

    _mapView.camera.altitude = kMapAltitudeDefault;
    _mapView.centerCoordinate = coordinate;

    [self.view addSubview:_mapView];
}

- (void)_createDashBoard
{
    CGFloat y = CGRectGetHeight(self.view.frame) - kMapDashBoardHeight;
    CGRect frame = CGRectMake(0, y, CGRectGetWidth(self.view.frame), kMapDashBoardHeight);

    _dashBoard = [[JYMapDashBoardView alloc] initWithFrame:frame withStyle:JYMapDashBoardStyleStartOnly];
    _dashBoard.delegate = self;

    [self.view addSubview:_dashBoard];
}

- (void)_zoomAndMoveMap
{
    CLLocationCoordinate2D newCenter = CLLocationCoordinate2DMake(_mapView.centerCoordinate.latitude + kMapEndPointCenterOffset,
                                                                  _mapView.centerCoordinate.longitude + kMapEndPointCenterOffset);

    MKCoordinateRegion newRegion = MKCoordinateRegionMakeWithDistance(newCenter, kMapSpanDistanceDefault, kMapSpanDistanceDefault);
    [_mapView setRegion:newRegion animated:YES];
}

- (void)_navigateToNextView
{
    UIViewController *viewController = [JYOrderCreateFormViewController new];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (BOOL)_shouldEditEndPoint
{
    if (self.mapEditMode != MapEditModeStartPoint)
    {
        return NO;
    }

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
            // do nothing
            break;
    }
    return result;
}

- (void)_showStartPointAnnotation:(BOOL)show
{
    if (show)
    {
        if (_startPoint == nil)
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
        if (_endPoint == nil)
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
        if (_startPointView == nil)
        {
            _startPointView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pinBlue"]];
            CGFloat y = (CGRectGetHeight(_mapView.frame) - CGRectGetHeight(_startPointView.frame)) / 2;
            _startPointView.center =  CGPointMake(CGRectGetWidth(_mapView.frame) / 2, y);

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
        if (_endPointView == nil)
        {
            _endPointView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pinPink"]];
            CGFloat y = (CGRectGetHeight(_mapView.frame) - CGRectGetHeight(_startPointView.frame)) / 2;
            _endPointView.center = CGPointMake(CGRectGetWidth(_mapView.frame) / 2, y);
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

#pragma mark - JYMapDashBoardViewDelegate

- (void)dashBoard:(JYMapDashBoardView *)dashBoard startButtonPressed:(MRoundedButton *)button
{

}

- (void)dashBoard:(JYMapDashBoardView *)dashBoard endButtonPressed:(MRoundedButton *)button
{

}

- (void)dashBoard:(JYMapDashBoardView *)dashBoard submitButtonPressed:(MRoundedButton *)button
{
    switch (self.mapEditMode) {
        case MapEditModeStartPoint:
            if ([self _shouldEditEndPoint])
            {
                self.mapEditMode = MapEditModeEndPoint;
                [self _zoomAndMoveMap];
            }
            else
            {
                [self _navigateToNextView];
            }
            break;
        case MapEditModeEndPoint:
            self.mapEditMode = MapEditModeDone;
            NSAssert(_startPoint && _endPoint, @"Both _startPoint and _endPoint annotations should exist");
            [_mapView showAnnotations:@[_startPoint, _endPoint] animated:YES];
            break;
        case MapEditModeDone:
            [self _navigateToNextView];
            break;
        default:
            break;
    }
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
        if (pinView == nil)
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

@end
