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
@property(nonatomic) NSMutableArray *bidsMatrix;
@property(nonatomic) NSMutableArray *ordersList;
@property(nonatomic) NSUInteger maxBidId;
@property(nonatomic) NSUInteger maxOrderId;
@property(nonatomic) UITableView *tableView;
@property(nonatomic) UIRefreshControl *refreshControl;

+ (UILabel *)sharedAcceptLabel;

@end

NSString *const kBidCellIdentifier = @"bidCell";

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
    self.ordersList = [NSMutableArray new];
    self.bidsMatrix = [NSMutableArray new];
    self.isFetchingData = NO;
    self.selectedIndexPath = nil;

    [self _fetchMyOrders];
    [self _createTableView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fetchMyOrders) name:kNotificationDidCreateOrder object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fetchMyOrders) name:kNotificationDidReceiveBid object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fetchMyBids) name:kNotificationDidCreateBid object:nil];
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
    [self.refreshControl addTarget:self action:@selector(_fetchMyOrders) forControlEvents:UIControlEventValueChanged];

    tableViewController.refreshControl = self.refreshControl;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.ordersList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *bids = (NSArray *)self.bidsMatrix[section];
    return bids.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYBidViewCell *cell =
    (JYBidViewCell *)[tableView dequeueReusableCellWithIdentifier:kBidCellIdentifier forIndexPath:indexPath];

    NSArray *bids = (NSArray *)[self.bidsMatrix objectAtIndex:indexPath.section];
    NSDictionary *bid = (NSDictionary *)[bids objectAtIndex:indexPath.row];

    NSUInteger price = [[bid objectForKey:@"price"] unsignedIntegerValue];
    cell.priceLabel.text = [NSString stringWithFormat:@"$%tu", price];

    cell.bidderNameLabel.text = [bid objectForKey:@"username"];

    NSTimeInterval expireTime = [[bid objectForKey:@"expire_at"] floatValue];
    [cell setExpireTime:expireTime];

    NSUInteger ratingTotal = [[bid objectForKey:@"rating_total"] unsignedIntegerValue];
    NSUInteger ratingCount = [[bid objectForKey:@"rating_count"] unsignedIntegerValue];
    [cell setRatingTotalScore:ratingTotal count:ratingCount];

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

    CGRect frame = [tableView cellForRowAtIndexPath:indexPath].frame;
    frame.origin.y -= tableView.contentOffset.y;
    actionSheet.clearArea = frame;
    [actionSheet showInView:self.view];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSDictionary *order = (NSDictionary *)self.ordersList[section];
    NSString *orderBodyText = [order objectForKey:@"note"];
    return [JYOrderItemView viewHeightForText:orderBodyText];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSDictionary *order = (NSDictionary *)self.ordersList[section];
    NSString *orderBodyText = [order objectForKey:@"note"];
    CGFloat height = [JYOrderItemView viewHeightForText:orderBodyText];

    JYOrderItemView *view = [[JYOrderItemView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), height)];
    view.bodyLabel.text = orderBodyText;
    view.titleLabel.text = [order objectForKey:@"title"];

    NSUInteger price = [[order objectForKey:@"price"] integerValue];
    view.priceLabel.text = [NSString stringWithFormat:@"$%tu", price];

    NSTimeInterval startTime = [[order objectForKey:@"starttime"] integerValue];
    [view setStartDateTime:[NSDate dateWithTimeIntervalSinceReferenceDate:startTime]];

    return view;
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
        NSArray *bids = (NSArray *)[self.bidsMatrix objectAtIndex:self.selectedIndexPath.section];
        NSDictionary *bid = (NSDictionary *)[bids objectAtIndex:self.selectedIndexPath.row];
        NSUInteger bidId = [[bid objectForKey:@"id"] unsignedIntegerValue];

        [self _acceptBid:bidId];
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

- (void)_fetchMyOrders
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

             NSMutableArray *newOrdersList = [NSMutableArray arrayWithArray:(NSArray *)responseObject];

             if (newOrdersList.count > 0)
             {
                 NSDictionary *order = [newOrdersList firstObject];
                 weakSelf.maxOrderId = [[order objectForKey:@"id"] unsignedIntegerValue];

                 // create bids array for new orders
                 for (NSUInteger i = 0; i < newOrdersList.count; ++i)
                 {
                     [weakSelf.bidsMatrix insertObject:[NSMutableArray new] atIndex:0];
                 }

                 [newOrdersList addObjectsFromArray:weakSelf.ordersList];
                 weakSelf.ordersList = newOrdersList;
             }

             weakSelf.isFetchingData = NO;

             if (weakSelf.ordersList.count > 0)
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

- (void)_fetchMyBids
{
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

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"bids/orders"];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

//             NSLog(@"bids/orders fetch success responseObject: %@", responseObject);
             NSArray *newBids = (NSArray *)responseObject;

             if (newBids.count > 0)
             {
                 NSDictionary *newestBid = [newBids firstObject];
                 weakSelf.maxBidId = [[newestBid objectForKey:@"id"] unsignedIntegerValue];

                 // bids are in DESC order, so iterate the newBids backward and insert each bid to the beginning of its array
                 for (NSDictionary *bid in [newBids reverseObjectEnumerator])
                 {
                     NSUInteger orderId = [[bid objectForKey:@"order_id"] unsignedIntegerValue];
                     NSUInteger orderIndex = [weakSelf _indexOfOrder:orderId];
                     if (orderIndex != NSUIntegerMax)
                     {
                         NSMutableArray *bidsArray = weakSelf.bidsMatrix[orderIndex];
                         [bidsArray insertObject:bid atIndex:0];
                     }
                 }
             }

             [weakSelf.refreshControl endRefreshing];
             [weakSelf.tableView reloadData];
             weakSelf.isFetchingData = NO;
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [weakSelf.refreshControl endRefreshing];
             weakSelf.isFetchingData = NO;
         }
     ];
}

- (NSUInteger)_indexOfOrder:(NSUInteger)targetOrderId
{
    NSUInteger index = 0;
    for (; index < self.ordersList.count; ++index)
    {
        NSUInteger orderId = [[self.ordersList[index] objectForKey:@"id"] unsignedIntegerValue];
        if (orderId == targetOrderId)
        {
            return index;
        }
    }
    return NSUIntegerMax;
}

- (NSDictionary *)_httpBidsParameters
{
    NSMutableArray *orderIds = [NSMutableArray new];
    for (NSDictionary *order in [self.ordersList objectEnumerator])
    {
        NSString *orderId = [order objectForKey:@"id"];
        [orderIds addObject:orderId];
    }

    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setValue:@(self.maxBidId) forKey:@"after"];
    [parameters setValue:orderIds forKey:@"order_id"];
    
    return parameters;
}

@end
