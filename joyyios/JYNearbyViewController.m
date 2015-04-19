//
//  JYNearbyViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "AppDelegate.h"
#import "JYNearbyViewController.h"
#import "JYOrderViewCell.h"
#import "JYUser.h"

@interface JYNearbyViewController ()

@property(nonatomic) NSMutableArray *ordersList;
@property(nonatomic) UITableView *tableView;
@property(nonatomic) UIRefreshControl *refreshControl;
@property(nonatomic) NSUInteger maxOrderId;

@end

NSString *const kOrderCellIdentifier = @"orderCell";

@implementation JYNearbyViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitleText:NSLocalizedString(@"Orders Nearby", nil)];

    self.maxOrderId = 0;
    self.ordersList = [NSMutableArray new];
    [self _fetchData];
    [self _createTableView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fetchData) name:kNotificationSignDidFinish object:nil];
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
    NSTimeInterval startTime = [[order valueForKey:@"starttime"] integerValue];

    [cell setStartDateTime:[NSDate dateWithTimeIntervalSinceReferenceDate:startTime]];

    // price
    NSUInteger price = [[order valueForKey:@"price"] integerValue];
    cell.priceLabel.text = [NSString stringWithFormat:@"$%tu", price];

    // create time
    [cell setCreateTime:[order valueForKey:@"created_at"]];

    // distance
    CLLocationDegrees lat = [[order valueForKey:@"startpointlat"] doubleValue];
    CLLocationDegrees lon = [[order valueForKey:@"startpointlon"] doubleValue];
    CLLocationCoordinate2D point = CLLocationCoordinate2DMake(lat, lon);
    [cell setDistanceFromPoint:point];

    cell.titleLabel.text = [order valueForKey:@"title"];
    cell.bodyLabel.text = [order valueForKey:@"note"];
    cell.cityLabel.text = [order valueForKey:@"startcity"];

    return cell;
}

#pragma mark -UIRefreshControl
- (void)refresh:(UIRefreshControl *)refreshControl
{
    [refreshControl endRefreshing];
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.ordersList.count == 0)
    {
        return 100;
    }

    NSDictionary *order = (NSDictionary *)[self.ordersList objectAtIndex:indexPath.row];
    NSString *note = [order valueForKey:@"note"];
    return [JYOrderViewCell cellHeightForText:note];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

#pragma mark - Network

- (void)_fetchData
{
    NSDictionary *parameters = [self _httpParameters];
//    NSLog(@"parameters = %@", parameters);

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/nearby"];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager GET:url
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"orders/nearby fetch success responseObject: %@", responseObject);

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

              NSMutableArray *newOrdersList = [NSMutableArray arrayWithArray:(NSArray *)responseObject];
              [newOrdersList addObjectsFromArray:weakSelf.ordersList];
              weakSelf.ordersList = newOrdersList;

              if (weakSelf.ordersList.count > 0)
              {
                  id order = [responseObject firstObject];
                  weakSelf.maxOrderId = [[order valueForKey:@"id"] unsignedIntegerValue];
              }

              [weakSelf.tableView reloadData];
              [weakSelf.refreshControl endRefreshing];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [weakSelf.refreshControl endRefreshing];
          }
     ];
}

-(NSDictionary *)_httpParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D currentPoint = appDelegate.currentLocation.coordinate;
    [parameters setValue:@(currentPoint.longitude) forKey:@"lon"];
    [parameters setValue:@(currentPoint.latitude) forKey:@"lat"];
    [parameters setValue:@(self.maxOrderId) forKey:@"after"];

    return parameters;
}
@end
