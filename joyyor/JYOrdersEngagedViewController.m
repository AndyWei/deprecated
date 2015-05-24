//
//  JYOrdersEngagedViewController.m
//  joyyor
//
//  Created by Ping Yang on 5/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYCommentViewCell.h"
#import "JYCommentsViewController.h"
#import "JYOrderItemView.h"
#import "JYOrdersEngagedViewController.h"
#import "JYUser.h"


@interface JYOrdersEngagedViewController ()

@property(nonatomic) NSInteger fetchThreadCount;
@property(nonatomic) NSMutableArray *commentMatrix;
@property(nonatomic) NSMutableArray *orderList;
@property(nonatomic) NSMutableDictionary *bidDict;
@property(nonatomic) NSUInteger maxOrderId;
@property(nonatomic) NSUInteger maxBidId;
@property(nonatomic) NSUInteger maxCommentId;
@property(nonatomic) UITableView *tableView;
@property(nonatomic) UIRefreshControl *refreshControl;

@end

static NSString *const kCommentCellIdentifier = @"commentCell";

@implementation JYOrdersEngagedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitleText:NSLocalizedString(@"Engaged Orders", nil)];

    self.maxOrderId = 0;
    self.maxBidId = 0;
    self.maxCommentId = 0;
    self.fetchThreadCount = 0;

    self.orderList = [NSMutableArray new];
    self.commentMatrix = [NSMutableArray new];
    self.bidDict = [NSMutableDictionary new];

    [self _fetchOrders];
    [self _createTableView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fetchOrders) name:kNotificationDidCreateBid object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fetchOrders) name:kNotificationDidCreateComment object:nil];
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
    self.tableView.separatorColor = ClearColor;
    self.tableView.backgroundColor = FlatGray;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[JYCommentViewCell class] forCellReuseIdentifier:kCommentCellIdentifier];
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

- (void)_presentCreateCommentViewWithOrder:(NSDictionary *)order comments:(NSArray *)comments orginalComment:(NSDictionary *)origin
{
    NSString *orderId = [order objectForKey:@"id"];
    NSDictionary *bid = [self.bidDict objectForKey:orderId];

    JYCommentsViewController *viewController = [[JYCommentsViewController alloc] initWithOrder:order bid:bid comments:comments];
    viewController.originalComment = origin;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (NSDictionary *)_orderOfId:(NSUInteger)targetOrderId
{
    NSDictionary *order = nil;
    for (NSUInteger index = 0; index < self.orderList.count; ++index)
    {
        order = self.orderList[index];
        NSUInteger orderId = [[order objectForKey:@"id"] unsignedIntegerValue];
        if (orderId == targetOrderId)
        {
            break;
        }
    }
    return order;
}

- (NSUInteger)_indexOfOrder:(NSUInteger)targetOrderId
{
    NSUInteger index = 0;
    for (; index < self.orderList.count; ++index)
    {
        NSUInteger orderId = [[self.orderList[index] objectForKey:@"id"] unsignedIntegerValue];
        if (orderId == targetOrderId)
        {
            return index;
        }
    }
    return NSUIntegerMax;
}

- (void)_fetchEndCheck
{
    if (self.fetchThreadCount == 0)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self.refreshControl endRefreshing];
        [self.tableView reloadData];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.orderList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *comments = (NSArray *)self.commentMatrix[section];
    return comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYCommentViewCell *cell =
    (JYCommentViewCell *)[tableView dequeueReusableCellWithIdentifier:kCommentCellIdentifier forIndexPath:indexPath];

    NSArray *comments = (NSArray *)[self.commentMatrix objectAtIndex:indexPath.section];
    NSDictionary *comment = (NSDictionary *)[comments objectAtIndex:indexPath.row];
    [cell presentComment:comment];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *comments = (NSArray *)[self.commentMatrix objectAtIndex:indexPath.section];
    NSDictionary *comment = (NSDictionary *)[comments objectAtIndex:indexPath.row];
    return [JYCommentViewCell cellHeightForComment:comment];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *order = self.orderList[indexPath.section];
    NSArray *comments = self.commentMatrix[indexPath.section];
    NSDictionary *orginalComment = comments[indexPath.row];
    [self _presentCreateCommentViewWithOrder:order comments:comments orginalComment:orginalComment];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSDictionary *order = (NSDictionary *)self.orderList[section];
    NSString *orderBodyText = [order objectForKey:@"note"];

    NSString *orderId = [order objectForKey:@"id"];
    NSDictionary *bid = [self.bidDict objectForKey:orderId];
    return [JYOrderItemView viewHeightForText:orderBodyText withBid:(bid != NULL)];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSDictionary *order = (NSDictionary *)self.orderList[section];
    NSString *orderId = [order objectForKey:@"id"];
    NSDictionary *bid = [self.bidDict objectForKey:orderId];

    NSString *orderBodyText = [order objectForKey:@"note"];
    CGFloat height = [JYOrderItemView viewHeightForText:orderBodyText withBid:(bid != NULL)];

    JYOrderItemView *itemView = [[JYOrderItemView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), height)];
    itemView.tinyLabelsHidden = NO;
    itemView.bidLabelHidden = (bid == NULL);
    itemView.viewColor = FlatWhite;
    [itemView presentOrder:order andBid:bid];

    return itemView;
}

#pragma mark - UIActionSheetDelegate

//-(void)customActionSheet:(UICustomActionSheet *)customActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    self.tabBarController.tabBar.hidden = NO;
//    if (!self.selectedIndexPath)
//    {
//        return;
//    }
//
//    [self.tableView deselectRowAtIndexPath:self.selectedIndexPath animated:YES];
//
//    if (buttonIndex == 1)
//    {
//        NSArray *bids = (NSArray *)[self.commentMatrix objectAtIndex:self.selectedIndexPath.section];
//        NSDictionary *bid = (NSDictionary *)[bids objectAtIndex:self.selectedIndexPath.row];
//        NSUInteger bidId = [[bid objectForKey:@"id"] unsignedIntegerValue];
//
//        [self _acceptBid:bidId];
//    }
//    self.selectedIndexPath = nil;
//}


#pragma mark - Network

- (void)_fetchOrders
{
    if (self.fetchThreadCount > 0)
    {
        return;
    }
    self.fetchThreadCount++;

    NSDictionary *parameters = @{@"after" : @(self.maxOrderId)};

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/engaged"];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
//             NSLog(@"orders/engaged fetch success responseObject: %@", responseObject);

             NSMutableArray *newOrderList = [NSMutableArray arrayWithArray:(NSArray *)responseObject];

             if (newOrderList.count > 0)
             {
                 NSDictionary *lastOrder = [newOrderList firstObject];
                 weakSelf.maxOrderId = [[lastOrder objectForKey:@"id"] unsignedIntegerValue];

                 // create comments array for new orders
                 for (NSUInteger i = 0; i < newOrderList.count; ++i)
                 {
                     [weakSelf.commentMatrix insertObject:[NSMutableArray new] atIndex:0];
                 }

                 [newOrderList addObjectsFromArray:weakSelf.orderList];
                 weakSelf.orderList = newOrderList;
             }

             weakSelf.self.fetchThreadCount--;

             if (weakSelf.orderList.count > 0)
             {
                 [weakSelf _fetchBids];
                 [weakSelf _fetchComments];
             }

             [weakSelf _fetchEndCheck];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             weakSelf.fetchThreadCount--;
             [weakSelf _fetchEndCheck];
         }
     ];
}

- (void)_fetchBids
{
    self.fetchThreadCount++;

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"bids/from_me"];
    NSDictionary *parameters = @{@"after" : @(self.maxBidId)};

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {

//             NSLog(@"bids/from_me fetch success responseObject: %@", responseObject);
             NSArray *bids = (NSArray *)responseObject;

             if (bids.count > 0)
             {
                 // bids are in DESC order
                 NSDictionary *lastBid = [bids firstObject];
                 weakSelf.maxBidId = [[lastBid objectForKey:@"id"] unsignedIntegerValue];

                 for (NSDictionary *bid in bids)
                 {
                     NSString *orderIdString = [bid objectForKey:@"order_id"];
                     [weakSelf.bidDict setObject:bid forKey:orderIdString];
                 }
             }

             weakSelf.fetchThreadCount--;
             [weakSelf _fetchEndCheck];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             weakSelf.fetchThreadCount--;
             [weakSelf _fetchEndCheck];;
         }
     ];
}

- (void)_fetchComments
{
    self.fetchThreadCount++;

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"comments/of/orders"];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:[self _httpCommentsParameters]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {

//             NSLog(@"comments/of/orders fetch success responseObject: %@", responseObject);
             NSArray *comments = (NSArray *)responseObject;

             if (comments.count > 0)
             {
                 NSDictionary *lastComment = [comments lastObject];
                 weakSelf.maxCommentId = [[lastComment objectForKey:@"id"] unsignedIntegerValue];

                 // comments are in ASC order, so iterate it forward and append each comment to its array
                 for (NSDictionary *comment in comments)
                 {
                     NSUInteger orderId = [[comment objectForKey:@"order_id"] unsignedIntegerValue];
                     NSUInteger orderIndex = [weakSelf _indexOfOrder:orderId];
                     if (orderIndex != NSUIntegerMax)
                     {
                         NSMutableArray *commentArray = weakSelf.commentMatrix[orderIndex];
                         [commentArray addObject:comment];
                     }
                 }
             }

             weakSelf.fetchThreadCount--;
             [weakSelf _fetchEndCheck];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             weakSelf.fetchThreadCount--;
             [weakSelf _fetchEndCheck];
         }
     ];
}

- (NSDictionary *)_httpCommentsParameters
{
    NSMutableArray *orderIds = [NSMutableArray new];
    for (NSDictionary *order in self.orderList)
    {
        NSString *orderId = [order objectForKey:@"id"];
        [orderIds addObject:orderId];
    }
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    [parameters setValue:@(self.maxCommentId) forKey:@"after"];
    [parameters setValue:orderIds forKey:@"order_id"];
    
    return parameters;
}

@end
