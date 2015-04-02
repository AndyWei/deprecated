//
//  JYOrderCreateLocationViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "JYOrderCreateLocationViewController.h"
#import "JYServiceCategory.h"
#import "MRoundedButton.h"

@interface JYOrderCreateLocationViewController ()
{
    MKMapView *_mapView;
    MRoundedButton *_nextButton;
}
@end

@implementation JYOrderCreateLocationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = [JYServiceCategory names][self.serviceCategoryIndex];

    [self _createMapView];
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

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    NSLog(@"%@", appDelegate.currentLocation);

    [self _createNextButton];

    [self.view addSubview:_mapView];
}

- (void)_createNextButton
{
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    CGFloat y = _mapView.frame.size.height - tabBarHeight - kNextButtonHeight - kNextButtonMarginBottom;
    CGRect frame = CGRectMake(kNextButtonMarginLeft, y, _mapView.frame.size.width - 2 * kNextButtonMarginLeft, kNextButtonHeight);

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
    [_mapView addSubview:_nextButton];
}

- (void)_next
{
}

@end
