//
//  JYOrdersUnpaidViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/25/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYOrdersUnpaidViewController.h"
#import "JYBidViewCell.h"
#import "JYOrderItemView.h"
#import "JYUser.h"

@interface JYOrdersUnpaidViewController ()

@property(nonatomic) BOOL isFetchingData;
@property(nonatomic) NSIndexPath *selectedIndexPath;
@property(nonatomic) NSMutableArray *orderList;
@property(nonatomic) NSUInteger maxBidId;
@property(nonatomic) NSUInteger maxOrderId;
@property(nonatomic) UITableView *tableView;
@property(nonatomic) UIRefreshControl *refreshControl;

+ (UILabel *)sharedAcceptLabel;

@end

static NSString *const kBidCellIdentifier = @"bidCell";

@implementation JYOrdersUnpaidViewController

+ (UILabel *)sharedAcceptLabel
{
    static UILabel *_sharedAcceptLabel = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedAcceptLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
        _sharedAcceptLabel.font = [UIFont systemFontOfSize:25];
        _sharedAcceptLabel.text = NSLocalizedString(@"Accept", nil);
        _sharedAcceptLabel.textColor = [UIColor whiteColor];
        _sharedAcceptLabel.textAlignment= NSTextAlignmentCenter;
    });

    return _sharedAcceptLabel;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitleText:NSLocalizedString(@"My Orders", nil)];

    self.maxBidId = 0;
    self.maxOrderId = 0;
    self.orderList = [NSMutableArray new];
    self.isFetchingData = NO;
    self.selectedIndexPath = nil;

    [self _fetchOrders];
    [self _createTableView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fetchOrders) name:kNotificationDidCreateOrder object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fetchOrders) name:kNotificationDidReceiveBid object:nil];
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
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = FlatGray;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[JYBidViewCell class] forCellReuseIdentifier:kBidCellIdentifier];
    [self.view addSubview:self.tableView];

    // Add UIRefreshControl
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;

    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(_fetchOrders) forControlEvents:UIControlEventValueChanged];

    tableViewController.refreshControl = self.refreshControl;
}

- (JYOrder *)_orderOfId:(NSUInteger)targetOrderId
{
    for (JYOrder *order in self.orderList)
    {
        if (order.orderId == targetOrderId)
        {
            return order;
        }
    }
    return nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.orderList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    JYOrder *order = self.orderList[section];
    return order.bids.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYBidViewCell *cell =
    (JYBidViewCell *)[tableView dequeueReusableCellWithIdentifier:kBidCellIdentifier forIndexPath:indexPath];

    JYOrder *order = self.orderList[indexPath.section];
    [cell presentBid:order.bids[indexPath.row]];
//    [self _createSwipeViewForCell:cell andOrder:order];
    return cell;
}

//- (void)_createSwipeViewForCell:(JYBidViewCell *)cell andOrder:(NSDictionary *)order
//{
//    __weak typeof(self) weakSelf = self;
//    [cell setSwipeGestureWithView:[[self class] sharedAcceptLabel]
//                            color:FlatGreen
//                             mode:MCSwipeTableViewCellModeSwitch
//                            state:MCSwipeTableViewCellState3
//                  completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
//                      [weakSelf _presentBidViewForOrder:order];
//                  }];
//
//    [cell setDefaultColor:FlatGreen];
//    cell.firstTrigger = 0.25;
//}



#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [JYBidViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedIndexPath = indexPath;
    self.tabBarController.tabBar.hidden = YES;

    UICustomActionSheet *actionSheet = [[UICustomActionSheet alloc] initWithTitle:nil delegate:self buttonTitles:@[NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Accept", nil)]];

    [actionSheet setButtonColors:@[JoyyBlue50, JoyyBlue]];
    [actionSheet setButtonsTextColor:JoyyWhite];
    actionSheet.backgroundColor = JoyyWhite;

    // Highlight the selected cell
    CGRect frame = [tableView cellForRowAtIndexPath:indexPath].frame;
    frame.origin.y -= tableView.contentOffset.y;
    actionSheet.clearArea = frame;

    [actionSheet showInView:self.view];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [JYOrderItemView viewHeightForOrder:self.orderList[section]];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    JYOrder *order = self.orderList[section];
    CGFloat height = [JYOrderItemView viewHeightForOrder:order];

    JYOrderItemView *itemView = [[JYOrderItemView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), height)];
    itemView.tinyLabelsHidden = YES;
    itemView.bidLabelHidden = YES;
    [itemView presentOrder:order];

    return itemView;
}

#pragma mark - UIActionSheetDelegate

-(void)customActionSheet:(UICustomActionSheet *)customActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.tabBarController.tabBar.hidden = NO;
    if (!self.selectedIndexPath)
    {
        return;
    }

    [self.tableView deselectRowAtIndexPath:self.selectedIndexPath animated:YES];

    if (buttonIndex == 1)
    {
        JYOrder *order = self.orderList[self.selectedIndexPath.section];
        JYBid *bid = order.bids[self.selectedIndexPath.row];

        [self _acceptBid:bid.bidId];
    }
    self.selectedIndexPath = nil;
}


#pragma mark - Network

- (void)_acceptBid:(NSUInteger)bidId
{
    NSDictionary *parameters = @{@"id" : @(bidId)};

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"bids/accept"];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager POST:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"bids/accept post success responseObject: %@", responseObject);

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [weakSelf _fetchBidsForOrders];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {

             NSLog(@"bids/accept post error: %@", error);

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
         }
     ];
}

- (void)_fetchOrders
{
    if (self.isFetchingData)
    {
        return;
    }
    self.isFetchingData = YES;

    NSDictionary *parameters = @{@"after" : @(self.maxOrderId)};

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/unpaid"];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
//             NSLog(@"orders/unpaid fetch success responseObject: %@", responseObject);

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [weakSelf.refreshControl endRefreshing];

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

             weakSelf.isFetchingData = NO;

             if (weakSelf.orderList.count > 0)
             {
                 [weakSelf _fetchBidsForOrders];
             }
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [weakSelf.refreshControl endRefreshing];
             weakSelf.isFetchingData = NO;
         }
     ];
}

- (void)_fetchBidsForOrders
{
    if (self.isFetchingData)
    {
        return;
    }
    self.isFetchingData = YES;

    NSDictionary *parameters = [self _httpBidsParameters];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"bids/of/orders"];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

//             NSLog(@"bids/orders fetch success responseObject: %@", responseObject);
             for (NSDictionary *dict in responseObject)
             {
                 JYBid *newBid = [[JYBid alloc] initWithDictionary:dict];
                 JYOrder *order = [weakSelf _orderOfId:newBid.orderId];
                 if (order != nil)
                 {
                     [order.bids addObject:newBid];
                     weakSelf.maxBidId = newBid.bidId; // new bids are in ASC order
                 }
             }

             [weakSelf.refreshControl endRefreshing];
             [weakSelf.tableView reloadData];
             NSIndexPath *indexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:0];
             [weakSelf.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
             weakSelf.isFetchingData = NO;
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [weakSelf.refreshControl endRefreshing];
             weakSelf.isFetchingData = NO;
         }
     ];
}

- (NSDictionary *)_httpBidsParameters
{
    NSMutableArray *orderIds = [NSMutableArray new];
    for (JYOrder *order in self.orderList)
    {
        [orderIds addObject:@(order.orderId)];
    }

    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setValue:@(self.maxBidId) forKey:@"after"];
    [parameters setValue:orderIds forKey:@"order_id"];

    return parameters;
}

@end
