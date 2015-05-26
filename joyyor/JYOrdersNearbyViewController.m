//
//  JYOrdersNearbyViewController.m
//  joyyor
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "AppDelegate.h"
#import "JYBid.h"
#import "JYBidCreateViewController.h"
#import "JYOrderViewCell.h"
#import "JYOrdersNearbyViewController.h"
#import "JYUser.h"

@interface JYOrdersNearbyViewController ()

@property(nonatomic) NSArray *commentsCountList;

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

    self.commentsCountList = [NSArray new];

    [self _createTableView];
    [self _fetchOrders];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchMyBids) name:kNotificationDidCreateBid object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_createTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.backgroundColor = FlatGray;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[JYOrderViewCell class] forCellReuseIdentifier:kOrderCellIdentifier];
    [self.view addSubview:self.tableView];

    // Add UIRefreshControl
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;

    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(_fetchOrders) forControlEvents:UIControlEventValueChanged];

    tableViewController.refreshControl = self.refreshControl;

    // Enable scroll to top
    self.scrollView = self.tableView;
}

- (void)_presentBidViewForOrder:(JYOrder *)order
{
    JYBidCreateViewController *bidViewController = [JYBidCreateViewController new];
    bidViewController.order = order;

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:bidViewController];
    [self presentViewController:nav animated:YES completion:nil];
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

    JYOrder *order = self.orderList[indexPath.row];
    [cell presentBiddedOrder:order];

    NSUInteger count = [[self.commentsCountList objectAtIndex:indexPath.row] unsignedIntegerValue];
    [cell updateCommentsCount:count];

    [self _createSwipeViewForCell:cell andOrder:order];
    return cell;
}

- (void)_createSwipeViewForCell:(JYOrderViewCell *)cell andOrder:(JYOrder *)order
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

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.orderList.count == 0)
    {
        return 100;
    }

    JYOrder *order = self.orderList[indexPath.row];
    return [JYOrderViewCell cellHeightForOrder:order];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self _presentBidViewForOrder:self.orderList[indexPath.row]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Network

- (void)_fetchOrders
{
    if (self.networkThreadCount > 0)
    {
        return;
    }
    [self networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/nearby"];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
       parameters:[self _httpParametersForOrdersNearBy]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
//              NSLog(@"orders/nearby fetch success responseObject: %@", responseObject);

              NSMutableArray *newOrderList = [NSMutableArray new];
              for (NSDictionary *dict in responseObject)
              {
                  JYOrder *newOrder = [[JYOrder alloc] initWithDictionary:dict];
                  [newOrderList addObject:newOrder];
              }

              if (newOrderList.count > 0)
              {
                  JYOrder *lastOrder = [newOrderList firstObject];
                  weakSelf.maxOrderId = lastOrder.orderId;

                  [newOrderList addObjectsFromArray:weakSelf.orderList];
                  weakSelf.orderList = newOrderList;
              }

              if (weakSelf.orderList.count > 0)
              {
                  [weakSelf fetchMyBids];
                  [weakSelf _fetchOrderCommentsCount];
              }

              [weakSelf networkThreadEnd];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [weakSelf networkThreadEnd];
          }
     ];
}

- (void)_fetchOrderCommentsCount
{
    [self networkThreadBegin];
    NSDictionary *parameters = [self _httpParametersForCommentsCount];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"comments/count/of/orders"];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"comments/count/of/orders fetch success responseObject: %@", responseObject);

             weakSelf.commentsCountList = (NSArray *)responseObject;
             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
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
    for (JYOrder *order in self.orderList)
    {
        [orderIds addObject:@(order.orderId)];
    }

    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setValue:orderIds forKey:@"order_id"];

    return parameters;
}
@end
