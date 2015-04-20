//
//  JYOrderBidViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/19/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYButton.h"
#import "JYOrderBidViewController.h"
#import "JYOrderViewCell.h"

@interface JYOrderBidViewController ()

@property(nonatomic) UITableView *tableView;
@property(nonatomic) UILabel *priceLabel;
@property(nonatomic) UITextField *priceTextField;
@property(nonatomic) CGFloat tableViewHeight;

@end

const CGFloat kBidControlsMarginTop = 20.0f;
NSString *const kOrderBidCellIdentifier = @"orderBidCell";

@implementation JYOrderBidViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Bid", nil);
    self.view.backgroundColor = [UIColor whiteColor];

    self.tableViewHeight = [JYOrderViewCell cellHeightForText:[self.order valueForKey:@"note"]];
    [self _createTableView];
    [self _createPriceLabel];
    [self _createPriceTextField];
    [self _createSubmitButton];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(_cancel)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Submit", nil)
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(_submit)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_cancel
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)_createTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    self.tableView.height = self.tableViewHeight + statusBarHeight + navBarHeight;
    self.tableView.backgroundColor = FlatWhite;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[JYOrderViewCell class] forCellReuseIdentifier:kOrderBidCellIdentifier];
    [self.view addSubview:self.tableView];
}

- (void)_createPriceLabel
{
    CGFloat y = CGRectGetMaxY(self.tableView.frame) + kBidControlsMarginTop;
    self.priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 150, 40)];
    self.priceLabel.font = [UIFont systemFontOfSize:25];
    self.priceLabel.textAlignment = NSTextAlignmentRight;
    self.priceLabel.textColor = FlatBlack;
    self.priceLabel.text = NSLocalizedString(@"Your Price: ", nil);

    [self.view addSubview:self.priceLabel];
}

- (void)_createPriceTextField
{
    CGFloat x = CGRectGetMaxX(self.priceLabel.frame) + 10;
    CGFloat y = CGRectGetMaxY(self.tableView.frame) + kBidControlsMarginTop;

    self.priceTextField = [[UITextField alloc] initWithFrame:CGRectMake(x, y, 150, 40)];
    self.priceTextField.backgroundColor = FlatWhite;
    self.priceTextField.font = [UIFont boldSystemFontOfSize:25];
    self.priceTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.priceTextField.text = @"$";
    self.priceTextField.textColor = FlatGreen;

    [self.view addSubview:self.priceTextField];
    [self.priceTextField becomeFirstResponder];
}

- (void)_createSubmitButton
{
    JYButton *submitButton = [JYButton button];
    submitButton.textLabel.text = NSLocalizedString(@"Submit", nil);

    [submitButton addTarget:self action:@selector(_submit) forControlEvents:UIControlEventTouchUpInside];
    self.priceTextField.inputAccessoryView = submitButton;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYOrderViewCell *cell =
    (JYOrderViewCell *)[tableView dequeueReusableCellWithIdentifier:kOrderBidCellIdentifier forIndexPath:indexPath];

    // start date and time
    NSTimeInterval startTime = [[self.order valueForKey:@"starttime"] integerValue];

    [cell setStartDateTime:[NSDate dateWithTimeIntervalSinceReferenceDate:startTime]];

    // price
    NSUInteger price = [[self.order valueForKey:@"price"] integerValue];
    cell.priceLabel.text = [NSString stringWithFormat:@"$%tu", price];

    // create time
    [cell setCreateTime:[self.order valueForKey:@"created_at"]];

    // distance
    CLLocationDegrees lat = [[self.order valueForKey:@"startpointlat"] doubleValue];
    CLLocationDegrees lon = [[self.order valueForKey:@"startpointlon"] doubleValue];
    CLLocationCoordinate2D point = CLLocationCoordinate2DMake(lat, lon);
    [cell setDistanceFromPoint:point];

    cell.titleLabel.text = [self.order valueForKey:@"title"];
    cell.bodyLabel.text = [self.order valueForKey:@"note"];
    cell.cityLabel.text = [self.order valueForKey:@"startcity"];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.tableViewHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Network

- (void)_submit
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
