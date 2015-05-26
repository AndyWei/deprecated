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
#import "JYComment.h"
#import "JYCommentsViewController.h"
#import "JYOrderViewCell.h"
#import "JYOrdersNearbyViewController.h"
#import "JYUser.h"

@interface JYOrdersNearbyViewController ()

@property(nonatomic) NSArray *commentsCountList;
@property(nonatomic) NSInteger selectedRow;

@end


static NSString *const kOrderCellIdentifier = @"orderCell";

@implementation JYOrdersNearbyViewController

+ (UILabel *)sharedBidLabel
{
    static UILabel *_sharedBidLabel = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedBidLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
        _sharedBidLabel.font = [UIFont systemFontOfSize:20];
        _sharedBidLabel.text = NSLocalizedString(@"Bid", nil);
        _sharedBidLabel.textColor = JoyyWhite;
        _sharedBidLabel.textAlignment= NSTextAlignmentCenter;
    });

    return _sharedBidLabel;
}

+ (UILabel *)sharedCommentLabel
{
    static UILabel *_sharedCommentLabel = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedCommentLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
        _sharedCommentLabel.font = [UIFont systemFontOfSize:20];
        _sharedCommentLabel.text = NSLocalizedString(@"Comment", nil);
        _sharedCommentLabel.textColor = JoyyWhite;
        _sharedCommentLabel.textAlignment= NSTextAlignmentCenter;
    });

    return _sharedCommentLabel;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitleText:NSLocalizedString(@"Orders Nearby", nil)];

    self.selectedRow = -1;
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

- (void)_presentCommentViewForOrder:(JYOrder *)order
{
    JYCommentsViewController *viewController = [[JYCommentsViewController alloc] initWithOrder:order];
    [self.navigationController pushViewController:viewController animated:YES];
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

    [cell setSwipeGestureWithView:[[self class] sharedCommentLabel]
                            color:FlatGray
                             mode:MCSwipeTableViewCellModeSwitch
                            state:MCSwipeTableViewCellState1
                  completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
                      [weakSelf _presentCommentViewForOrder:order];
                  }];

    [cell setSwipeGestureWithView:[[self class] sharedBidLabel]
                            color:FlatGray
                             mode:MCSwipeTableViewCellModeSwitch
                            state:MCSwipeTableViewCellState3
                  completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
                      [weakSelf _presentBidViewForOrder:order];
                  }];

    [cell setDefaultColor:FlatGray];
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
    self.selectedRow = indexPath.row;
    JYOrder *order = self.orderList[indexPath.row];
    [self _fetchCommentsOfOrder:order];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self showActionSheetForOrder:order highlightView:cell];

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - UIActionSheetDelegate

-(void)customActionSheet:(UICustomActionSheet *)customActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.tabBarController.tabBar.hidden = NO;
    if (self.selectedRow < 0)
    {
        return;
    }

    JYOrder *order = self.orderList[self.selectedRow];

    if (buttonIndex == 1) // create comment
    {
        [self _presentCommentViewForOrder:order];
    }
    else if (buttonIndex == 2) // create or update bid
    {
        // TODO: add logic for update bid
        //        NSString *orderId = [order objectForKey:@"id"];
        //        NSDictionary *bid = [self.bidDict objectForKey:orderId];
        [self _presentBidViewForOrder:order];

    }
    self.selectedRow = -1;
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

- (void)_fetchCommentsOfOrder:(JYOrder *)order
{
    [self networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"comments/of/orders"];
    NSDictionary *parameters = [self _httpParametersForCommentsOfOrder:order];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {

//             NSLog(@"comments/of/orders fetch success responseObject: %@", responseObject);

             for (NSDictionary *dict in responseObject)
             {
                 JYComment *newComment = [[JYComment alloc] initWithDictionary:dict];
                 [order.comments addObject:newComment];
             }

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

- (NSDictionary *)_httpParametersForCommentsOfOrder:(JYOrder *)order
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:@(order.orderId) forKey:@"order_id"];
    if (order.comments.count > 0)
    {
        JYComment *lastComment = [order.comments lastObject];
        [parameters setObject:@(lastComment.commentId) forKey:@"after"];
    }

    return parameters;
}

@end
