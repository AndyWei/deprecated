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

typedef NS_ENUM(NSUInteger, MapEditMode)
{
    MapEditModeNone = 0,
    MapEditModeStartPoint,
    MapEditModeEndPoint,
    MapEditModeDone
};

@interface JYOrderCreateLocationViewController ()
{
    JYPinchGestureRecognizer *_pintchRecognizer;
    MKMapView *_mapView;
    MKPointAnnotation *_startPoint;
    MKPointAnnotation *_endPoint;
    MRoundedButton *_nextButton;
    UIImageView *_startPointView;
    UIImageView *_endPointView;
}

@property(nonatomic) MapEditMode mapEditMode;

@end

static NSString *reuseId = @"pin";

@implementation JYOrderCreateLocationViewController

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = NSLocalizedString(@"Location", nil);

    _mapEditMode = MapEditModeNone;
    [self _createMapView];
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

    _mapEditMode = mode;
    // Prepare for new mode
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
    [self _updateNextButton];
}

- (void)_createMapView
{
    CGFloat topMargin = ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height);
    CGFloat bottomMargin = kNextButtonHeight;
    CGRect frame = CGRectMake(0, topMargin, self.view.frame.size.width, self.view.frame.size.height - bottomMargin - topMargin);
    _mapView = [[MKMapView alloc] initWithFrame:frame];
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

    _mapView.camera.altitude = 500;
    _mapView.centerCoordinate = coordinate;


    [self.view addSubview:_mapView];
    self.mapEditMode = MapEditModeStartPoint;
}

- (void)_createNextButton
{
    CGFloat y = self.view.frame.size.height - kNextButtonHeight;
    CGRect frame = CGRectMake(0, y, self.view.frame.size.width, kNextButtonHeight);

    _nextButton = [[MRoundedButton alloc] initWithFrame:frame buttonStyle:MRoundedButtonDefault];
    _nextButton.contentAnimateToColor = FlatGray;
    _nextButton.contentColor = FlatWhite;
    _nextButton.foregroundColor = JoyyBlue;
    _nextButton.foregroundAnimateToColor = FlatWhite;
    _nextButton.textLabel.font = [UIFont boldSystemFontOfSize:kSignFieldFontSize];

    [_nextButton addTarget:self action:@selector(_nextButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_nextButton];
}

- (void)_updateNextButton
{
    if (_nextButton == nil)
    {
        [self _createNextButton];
    }

    if (self.mapEditMode == MapEditModeDone)
    {
        _nextButton.textLabel.text = NSLocalizedString(@"Next", nil);
        return;
    }

    NSString *text = nil;
    switch (self.serviceCategoryIndex)
    {
        case JYServiceCategoryIndexCleaning:
        case JYServiceCategoryIndexGardener:
        case JYServiceCategoryIndexHandyman:
        case JYServiceCategoryIndexPersonalAssistant:
        case JYServiceCategoryIndexPlumbing:
        case JYServiceCategoryIndexRoadsideAssistance:
        case JYServiceCategoryIndexOther:
            text = NSLocalizedString(@"Set Sevice Location", nil);
            break;
        case JYServiceCategoryIndexDelivery:
        case JYServiceCategoryIndexMoving:
        case JYServiceCategoryIndexRide:
            if (_mapEditMode == MapEditModeStartPoint)
            {
                text = NSLocalizedString(@"Set Pickup Location", nil);
            }
            else
            {
                text = NSLocalizedString(@"Set Destination Location", nil);
            }
            break;
        default:
            text = NSLocalizedString(@"Next", nil);
            break;
    }
    _nextButton.textLabel.text = text;
}

- (void)_nextButtonPressed
{
    switch (self.mapEditMode) {
        case MapEditModeStartPoint:
            if ([self _shouldEditEndPoint])
            {
                self.mapEditMode = MapEditModeEndPoint;
                [self _moveMap];
            }
            else
            {
                [self _navigateToCreateFormView];
            }
            break;
        case MapEditModeEndPoint:
            self.mapEditMode = MapEditModeDone;
            break;
        case MapEditModeDone:
            [self _navigateToCreateFormView];
            break;
        default:
            break;
    }
}

- (void)_moveMap
{
    CLLocationCoordinate2D newCenter = CLLocationCoordinate2DMake(_mapView.centerCoordinate.latitude - 0.001,
                                                                  _mapView.centerCoordinate.longitude + 0.001);

    [_mapView setCenterCoordinate:newCenter animated:YES];
}

- (void)_navigateToCreateFormView
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
            CGFloat yOffset = _startPointView.frame.size.height / 2;
            _startPointView.center =  CGPointMake(_mapView.frame.size.width / 2, _mapView.frame.size.height / 2 - yOffset);

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
            CGFloat yOffset = _endPointView.frame.size.height / 2;
            _endPointView.center = CGPointMake(_mapView.frame.size.width / 2, _mapView.frame.size.height / 2 - yOffset);
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
            pinView.pinColor = [kAnnotationTitleStart isEqualToString:annotation.title] ? JYPinAnnotationColorBlue : JYPinAnnotationColorPink;
        }
        else
        {
            pinView.annotation = annotation;
        }
    }
    return pinView;
}

@end
