//
//  JYOrderCreateLocationViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "JYOrderCreateLocationViewController.h"
#import "JYPinAnnotationView.h"
#import "JYPinchGestureRecognizer.h"
#import "JYPinchGestureRecognizer.h"
#import "JYServiceCategory.h"
#import "MRoundedButton.h"

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
@end

static NSString *reuseId = @"pin";

@implementation JYOrderCreateLocationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = [JYServiceCategory names][self.serviceCategoryIndex];

    [self _createMapView];
    [self _createNextButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_createMapView
{
    _mapView = [[MKMapView alloc] initWithFrame:self.view.frame];
    _mapView.delegate = self;
    _mapView.showsUserLocation = YES;
    _mapView.pitchEnabled = NO;
    _mapView.rotateEnabled = NO;

    // To resolve the map center moving while zooming issue, distable default scrolling and zooming and
    // use our own pintch and pan gesture recognizer
    _mapView.scrollEnabled = NO;
    _mapView.zoomEnabled = YES;

    _pintchRecognizer = [[JYPinchGestureRecognizer alloc] initWithMapView:_mapView];
    [_mapView addGestureRecognizer: _pintchRecognizer];

    // The _mapView.userlocation hasn't been initiated at this time point, so use the currentLocation in AppDelegate
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D coordinate = appDelegate.currentLocation.coordinate;

    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000);
    [_mapView setRegion:region animated:YES];

    [self _showStartPointView:YES];
    [self _showEndPointView:NO];

    [self.view addSubview:_mapView];
}

- (void)_createNextButton
{
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    CGFloat y = self.view.frame.size.height - tabBarHeight - kNextButtonHeight - kNextButtonMarginBottom;
    CGRect frame = CGRectMake(kNextButtonMarginLeft, y, self.view.frame.size.width - 2 * kNextButtonMarginLeft, kNextButtonHeight);

    _nextButton = [[MRoundedButton alloc] initWithFrame:frame buttonStyle:MRoundedButtonDefault];
    _nextButton.borderWidth = 2;
    _nextButton.borderColor = ClearColor;
    _nextButton.contentAnimateToColor = FlatGray;
    _nextButton.contentColor = FlatWhite;
    _nextButton.cornerRadius = kButtonCornerRadius;
    _nextButton.foregroundColor = JoyyBlue50;
    _nextButton.foregroundAnimateToColor = FlatWhite;
    _nextButton.textLabel.font = [UIFont boldSystemFontOfSize:kSignFieldFontSize];
    _nextButton.textLabel.text = NSLocalizedString(@"Next", nil);

    [_nextButton addTarget:self action:@selector(_next) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_nextButton];
}

- (void)_addAnnotation:(NSString *)title
{
    if ([kAnnotationTitleStart isEqualToString:title])
    {
        _startPoint = [MKPointAnnotation new];
        _startPoint.coordinate = _mapView.centerCoordinate;
        _startPoint.title = title;
        [_mapView addAnnotation:_startPoint];
    }
    else if ([kAnnotationTitleEnd isEqualToString:title])
    {
        _endPoint = [MKPointAnnotation new];
        _endPoint.coordinate = _mapView.centerCoordinate;
        _endPoint.title = kAnnotationTitleEnd;
    }
}

- (void)_showStartPointView:(BOOL)show
{
    if (show)
    {
        if (_startPointView)
        {
            _startPointView.alpha = 1.0f;
        }
        else
        {
            _startPointView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pinBlue"]];
            CGFloat yOffset = _startPointView.frame.size.height / 2;
            _startPointView.center = CGPointMake(_mapView.center.x, _mapView.center.y - yOffset);
            [_mapView addSubview:_startPointView];
        }
    }
    else
    {
        if (_startPointView)
        {
            _startPointView.alpha = 0.0f;
        }
    }
}

- (void)_showEndPointView:(BOOL)show
{
    if (show)
    {
        if (_endPointView)
        {
            _endPointView.alpha = 1.0f;
        }
        else
        {
            _endPointView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pinBlue"]];
            CGFloat yOffset = _endPointView.frame.size.height / 2;
            _endPointView.center = CGPointMake(_mapView.center.x, _mapView.center.y - yOffset);
            [_mapView addSubview:_endPointView];
        }
    }
    else
    {
        if (_endPointView)
        {
            _endPointView.alpha = 0.0f;
        }
    }
}

- (void)_next
{
    [self _showStartPointView:NO];
    [self _addAnnotation:kAnnotationTitleStart];
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

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
}

@end
