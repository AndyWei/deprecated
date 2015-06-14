//
//  JYOrdersEngagedViewController.m
//  joyyor
//
//  Created by Ping Yang on 5/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "JYBidCreateViewController.h"
#import "JYComment.h"
#import "JYCommentViewCell.h"
#import "JYCommentsViewController.h"
#import "JYOrder.h"
#import "JYOrderItemView.h"
#import "JYOrdersEngagedViewController.h"
#import "JYUser.h"


@interface JYOrdersEngagedViewController ()

@property(nonatomic) NSInteger selectedSection;
@property(nonatomic) NSUInteger maxCommentId;

@end

static NSString *const kCommentCellIdentifier = @"commentCell";

@implementation JYOrdersEngagedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitleText:NSLocalizedString(@"Engaged Orders", nil)];

    self.maxCommentId = 0;
    self.selectedSection = -1;

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
    self.tableView.backgroundColor = FlatWhite;
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

- (void)_presentBidViewForOrder:(JYOrder *)order
{
    JYBidCreateViewController *bidViewController = [JYBidCreateViewController new];
    bidViewController.order = order;

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:bidViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)_presentCommentViewForOrder:(JYOrder *)order replyTo:(NSInteger)originCommentIndex
{
    JYCommentsViewController *viewController = [[JYCommentsViewController alloc] initWithOrder:order];
    viewController.originalCommentIndex = originCommentIndex;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)_tapOnTableSectionHeader:(id)sender
{
    JYOrderItemView *itemView = (JYOrderItemView *)sender;
    self.selectedSection = itemView.tag;

    JYOrder *order = self.orderList[self.selectedSection];
    [self showActionSheetForOrder:order highlightView:itemView];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.orderList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    JYOrder *order = self.orderList[section];
    return order.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYCommentViewCell *cell =
    (JYCommentViewCell *)[tableView dequeueReusableCellWithIdentifier:kCommentCellIdentifier forIndexPath:indexPath];

    JYOrder *order = self.orderList[indexPath.section];
    [cell presentComment:order.comments[indexPath.row]];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYOrder *order = self.orderList[indexPath.section];
    return [JYCommentViewCell cellHeightForComment:order.comments[indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYOrder *order = self.orderList[indexPath.section];

    [self _presentCommentViewForOrder:order replyTo:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    JYOrder *order = self.orderList[section];
    return [JYOrderItemView viewHeightForBiddedOrder:order];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    JYOrder *order = self.orderList[section];
    CGFloat height = [JYOrderItemView viewHeightForBiddedOrder:order];

    JYOrderItemView *itemView = [[JYOrderItemView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), height)];

    // make the order item view tappable
    itemView.tag = section;
    [itemView addTarget:self action: @selector(_tapOnTableSectionHeader:) forControlEvents:UIControlEventTouchUpInside];

    // show order
    itemView.tinyLabelsHidden = NO;
    itemView.bidLabelHidden = (order.bids.count == 0);
    [itemView presentBiddedOrder:order];

    return itemView;
}

#pragma mark - UIActionSheetDelegate

-(void)customActionSheet:(UICustomActionSheet *)customActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.tabBarController.tabBar.hidden = NO;
    if (self.selectedSection < 0)
    {
        return;
    }

    JYOrder *order = self.orderList[self.selectedSection];

    if (buttonIndex == 1) // create comment
    {
        [self _presentCommentViewForOrder:order replyTo:-1];
    }
    else if (buttonIndex == 2) // create or update bid
    {
        [self _presentBidViewForOrder:order];

    }
    self.selectedSection = -1;
}

#pragma mark - Network

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

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/engaged"];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
//             NSLog(@"orders/engaged fetch success responseObject: %@", responseObject);

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
                 [weakSelf _fetchBids];
                 [weakSelf _fetchComments];
             }

             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];
}

- (void)_fetchBids
{
    [self networkThreadBegin];

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
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];
}

- (void)_fetchComments
{
    [self networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"comments/of/orders"];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:[self _httpCommentsParameters]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {

//             NSLog(@"comments/of/orders fetch success responseObject: %@", responseObject);
             NSArray *comments = (NSArray *)responseObject;

             for (NSDictionary *dict in comments)
             {
                 JYComment *newComment = [[JYComment alloc] initWithDictionary:dict];

                 JYOrder *order = [weakSelf orderOfId:newComment.orderId];
                 if (order != nil)
                 {
                     [order.comments addObject:newComment];
                     weakSelf.maxCommentId = newComment.commentId; // new comments are in ASC order
                 }
             }

             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];
}

- (NSDictionary *)_httpCommentsParameters
{
    NSMutableArray *orderIds = [NSMutableArray new];
    for (JYOrder *order in self.orderList)
    {
        [orderIds addObject:@(order.orderId)];
    }
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    [parameters setValue:@(self.maxCommentId) forKey:@"after"];
    [parameters setValue:orderIds forKey:@"order_id"];
    
    return parameters;
}

@end
