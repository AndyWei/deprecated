//
//  JYOrdersNearbyViewController.m
//  joyyor
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "AppDelegate.h"
#import "JYOrdersNearbyViewController.h"
#import "JYBidCreateViewController.h"
#import "JYOrderViewCell.h"
#import "JYUser.h"

@interface JYOrdersNearbyViewController ()

@property(nonatomic) BOOL isFetchingData;
@property(nonatomic) NSArray *commentsCountList;
@property(nonatomic) NSMutableArray *orderList;
@property(nonatomic) NSUInteger maxOrderId;
@property(nonatomic) UITableView *tableView;
@property(nonatomic) UIRefreshControl *refreshControl;

+ (UILabel *)sharedSwipeBackgroundLabel;

@end

static NSString *const kOrderCellIdentifier = @"orderCell";

@implementation JYOrdersNearbyViewController

+ (UILabel *)sharedSwipeBackgroundLabel
{
    static UILabel *_sharedSwipeBackgroundLabel = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedSwipeBackgroundLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
        _sharedSwipeBackgroundLabel.font = [UIFont systemFontOfSize:25];
        _sharedSwipeBackgroundLabel.text = NSLocalizedString(@"Bid", nil);
        _sharedSwipeBackgroundLabel.textColor = [UIColor whiteColor];
        _sharedSwipeBackgroundLabel.textAlignment= NSTextAlignmentCenter;
    });

    return _sharedSwipeBackgroundLabel;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitleText:NSLocalizedString(@"Orders Nearby", nil)];

    self.maxOrderId = 0;
    self.commentsCountList = [NSArray new];
    self.orderList = [NSMutableArray new];
    self.isFetchingData = NO;
    [self _fetchData];
    [self _createTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    self.orderList = nil;
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
    return [self.orderList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYOrderViewCell *cell =
    (JYOrderViewCell *)[tableView dequeueReusableCellWithIdentifier:kOrderCellIdentifier forIndexPath:indexPath];

    NSDictionary *order = (NSDictionary *)[self.orderList objectAtIndex:indexPath.row];
    [cell presentOrder:order];

    NSUInteger count = [[self.commentsCountList objectAtIndex:indexPath.row] unsignedIntegerValue];
    [cell updateCommentsCount:count];

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
                      [weakSelf _presentBidViewForOrder:order];
                  }];

    [cell setDefaultColor:FlatGreen];
    cell.firstTrigger = 0.20;
}

- (void)_presentBidViewForOrder:(NSDictionary *)order
{
    JYBidCreateViewController *bidViewController = [JYBidCreateViewController new];
    bidViewController.order = order;

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:bidViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.orderList.count == 0)
    {
        return 100;
    }

    NSDictionary *order = (NSDictionary *)[self.orderList objectAtIndex:indexPath.row];
    NSString *note = [order objectForKey:@"note"];
    return [JYOrderViewCell cellHeightForText:note];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self _presentBidViewForOrder:(NSDictionary *)self.orderList[indexPath.row]];
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
    NSLog(@"orders/nearby start fetch data");

    NSDictionary *parameters = [self _httpParametersForOrdersNearBy];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/nearby"];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager GET:url
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"orders/nearby fetch success responseObject: %@", responseObject);

              NSMutableArray *newOrderList = [NSMutableArray arrayWithArray:(NSArray *)responseObject];

              if (newOrderList.count > 0)
              {
                  id order = [newOrderList firstObject];
                  weakSelf.maxOrderId = [[order objectForKey:@"id"] unsignedIntegerValue];
                  [newOrderList addObjectsFromArray:weakSelf.orderList];
                  weakSelf.orderList = newOrderList;
              }

              [weakSelf _fetchOrderCommentsCount];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [weakSelf.refreshControl endRefreshing];
              weakSelf.isFetchingData = NO;
          }
     ];
}

- (void)_fetchOrderCommentsCount
{
    NSLog(@"comments/count/of/orders start fetch data");

    NSDictionary *parameters = [self _httpParametersForCommentsCount];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"comments/count/of/orders"];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"comments/count/of/orders fetch success responseObject: %@", responseObject);

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

             weakSelf.commentsCountList = (NSArray *)responseObject;
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

-(NSDictionary *)_httpParametersForOrdersNearBy
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D currentPoint = appDelegate.currentCoordinate;
    [parameters setValue:@(currentPoint.longitude) forKey:@"lon"];
    [parameters setValue:@(currentPoint.latitude) forKey:@"lat"];
    [parameters setValue:@(self.maxOrderId) forKey:@"after"];

    return parameters;
}

- (NSDictionary *)_httpParametersForCommentsCount
{
    NSMutableArray *orderIds = [NSMutableArray new];
    for (NSDictionary *order in [self.orderList objectEnumerator])
    {
        NSString *orderId = [order objectForKey:@"id"];
        [orderIds addObject:orderId];
    }

    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setValue:orderIds forKey:@"order_id"];

    return parameters;
}
@end
