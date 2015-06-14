//
//  JYOrdersUnpaidViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/25/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "JYOrdersUnpaidViewController.h"
#import "JYBidViewCell.h"
#import "JYOrderCard.h"
#import "JYUser.h"
#import "UICustomActionSheet.h"

@interface JYOrdersUnpaidViewController ()

@property(nonatomic) NSIndexPath *selectedIndexPath;

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

    self.selectedIndexPath = nil;

    [self _createTableView];
    [self _fetchOrders];

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
    return [JYOrderCard cardHeightForOrder:self.orderList[section] withAddress:NO andBid:NO];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    JYOrder *order = self.orderList[section];
    CGFloat height = [JYOrderCard cardHeightForOrder:order withAddress:NO andBid:NO];

    JYOrderCard *card = [[JYOrderCard alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), height)];
    card.tinyLabelsHidden = YES;
    [card presentOrder:order withAddress:NO andBid:NO];

    return card;
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
    [self networkThreadBegin];
    NSDictionary *parameters = @{@"id" : @(bidId)};

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"bids/accept"];

    __weak typeof(self) weakSelf = self;
    [manager POST:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"bids/accept post success responseObject: %@", responseObject);

             [weakSelf _fetchBidsForOrders];
             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {

             NSLog(@"bids/accept post error: %@", error);
             [weakSelf networkThreadEnd];
         }
     ];
}

- (void)_fetchOrders
{
    if (self.networkThreadCount > 0)
    {
        return;
    }
    [self networkThreadBegin];

    NSDictionary *parameters = @{@"after" : @(self.maxOrderId)};

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/unpaid"];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
//             NSLog(@"orders/unpaid fetch success responseObject: %@", responseObject);

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
                 [weakSelf _fetchBidsForOrders];
             }
             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];
}

- (void)_fetchBidsForOrders
{
    [self networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"bids/of/orders"];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:[self _httpBidsParameters]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {

             //  NSLog(@"bids/orders fetch success responseObject: %@", responseObject);
             for (NSDictionary *dict in responseObject)
             {
                 JYBid *newBid = [[JYBid alloc] initWithDictionary:dict];
                 JYOrder *order = [weakSelf orderOfId:newBid.orderId];
                 if (order != nil)
                 {
                     [order.bids addObject:newBid];
                     weakSelf.maxBidId = newBid.bidId; // new bids are in ASC order
                 }
             }

             [weakSelf networkThreadEnd];
             NSIndexPath *indexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:0];
             [weakSelf.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
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
