//
//  JYOrdersTodoViewController.m
//  joyyor
//
//  Created by Ping Yang on 5/3/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "AppDelegate.h"
#import "JYOrdersTodoViewController.h"
#import "JYOrderViewCell.h"
#import "JYUser.h"

@interface JYOrdersTodoViewController ()

@property(nonatomic) BOOL isFetchingData;
@property(nonatomic) NSArray *ordersList;
@property(nonatomic) UITableView *tableView;
@property(nonatomic) UIRefreshControl *refreshControl;

+ (UILabel *)sharedSwipeBackgroundLabel;

@end

static NSString *const kOrderCellIdentifier = @"orderCell";

@implementation JYOrdersTodoViewController

+ (UILabel *)sharedSwipeBackgroundLabel
{
    static UILabel *_sharedSwipeBackgroundLabel = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedSwipeBackgroundLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
        _sharedSwipeBackgroundLabel.font = [UIFont systemFontOfSize:25];
        _sharedSwipeBackgroundLabel.text = NSLocalizedString(@"Start", nil);
        _sharedSwipeBackgroundLabel.textColor = [UIColor whiteColor];
        _sharedSwipeBackgroundLabel.textAlignment= NSTextAlignmentCenter;
    });

    return _sharedSwipeBackgroundLabel;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitleText:NSLocalizedString(@"Orders Toto", nil)];

    self.ordersList = [NSArray new];
    self.isFetchingData = NO;
    [self _fetchData];
    [self _createTableView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fetchData) name:kNotificationBidAccepted object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_createTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.backgroundColor = FlatWhite;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[JYOrderViewCell class] forCellReuseIdentifier:kOrderCellIdentifier];
    [self.view addSubview:self.tableView];

    // Add UIRefreshControl
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;

    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(_fetchData) forControlEvents:UIControlEventValueChanged];

    tableViewController.refreshControl = self.refreshControl;

    // Enable scroll to top
    self.scrollView = self.tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.ordersList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYOrderViewCell *cell =
    (JYOrderViewCell *)[tableView dequeueReusableCellWithIdentifier:kOrderCellIdentifier forIndexPath:indexPath];

    NSDictionary *order = (NSDictionary *)[self.ordersList objectAtIndex:indexPath.row];

    // start date and time
    NSTimeInterval startTime = [[order objectForKey:@"starttime"] integerValue];

    [cell setStartDateTime:[NSDate dateWithTimeIntervalSinceReferenceDate:startTime]];

    // price
    NSUInteger price = [[order objectForKey:@"price"] integerValue];
    cell.priceLabel.text = [NSString stringWithFormat:@"$%tu", price];

    // create time
    [cell setCreateTime:[order objectForKey:@"created_at"]];

    // distance
    CLLocationDegrees lat = [[order objectForKey:@"startpointlat"] doubleValue];
    CLLocationDegrees lon = [[order objectForKey:@"startpointlon"] doubleValue];
    CLLocationCoordinate2D point = CLLocationCoordinate2DMake(lat, lon);
    [cell setDistanceFromPoint:point];

    cell.titleLabel.text = [order objectForKey:@"title"];
    cell.bodyLabel.text = [order objectForKey:@"note"];
    cell.cityLabel.text = [order objectForKey:@"startcity"];

    [self _createSwipeViewForCell:cell andOrder:order];
    return cell;
}

- (void)_createSwipeViewForCell:(JYOrderViewCell *)cell andOrder:(NSDictionary *)order
{
    __weak typeof(self) weakSelf = self;
    [cell setSwipeGestureWithView:[[self class] sharedSwipeBackgroundLabel]
                            color:FlatGreen
                             mode:MCSwipeTableViewCellModeSwitch
                            state:MCSwipeTableViewCellState3
                  completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
                      [weakSelf _startWorkOn:order];
                  }];

    [cell setDefaultColor:FlatGreen];
    cell.firstTrigger = 0.20;
}

- (void)_startWorkOn:(NSDictionary *)order
{

}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.ordersList.count == 0)
    {
        return 100;
    }

    NSDictionary *order = (NSDictionary *)[self.ordersList objectAtIndex:indexPath.row];
    NSString *note = [order objectForKey:@"note"];
    return [JYOrderViewCell cellHeightForText:note];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self _startWorkOn:(NSDictionary *)self.ordersList[indexPath.row]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Network

- (void)_fetchData
{
    if (self.isFetchingData)
    {
        return;
    }
    self.isFetchingData = YES;

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/won"];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"orders/won fetch success responseObject: %@", responseObject);

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

             weakSelf.ordersList = (NSArray *)responseObject;
             [weakSelf.tableView reloadData];
             [weakSelf.refreshControl endRefreshing];
             weakSelf.isFetchingData = NO;
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [weakSelf.refreshControl endRefreshing];
             weakSelf.isFetchingData = NO;
         }
     ];
}

@end
