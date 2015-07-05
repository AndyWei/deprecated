//
//  JYOrdersOngoingViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/25/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>

#import "JYOrderViewCell.h"
#import "JYOrdersViewController.h"
#import "JYUser.h"
#import "UICustomActionSheet.h"

@interface JYOrdersViewController ()

@property(nonatomic) NSMutableArray *dealtOrderList;
@property(nonatomic) NSMutableArray *startedOrderList;
@property(nonatomic) NSMutableArray *finishedOrderList;
@property(nonatomic) NSIndexPath *selectedIndexPath;

@end


static NSString *const kOrderCellIdentifier = @"orderCell";

@implementation JYOrdersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"ORDERS", nil);

    self.selectedIndexPath = nil;

    self.dealtOrderList = [NSMutableArray new];
    self.startedOrderList = [NSMutableArray new];
    self.finishedOrderList = [NSMutableArray new];

    [self _createTableView];
    [self _fetchOrders];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
}

- (void)_createTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.backgroundColor = FlatBlack;
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
}

- (JYInvite *)_orderAt:(NSIndexPath *)indexPath
{
    JYInvite *order = nil;
    NSInteger index = indexPath.row;

    if (index < self.finishedOrderList.count)
    {
        order = self.finishedOrderList[index];
        return order;
    }
    index -= self.finishedOrderList.count;

    if (index < self.startedOrderList.count)
    {
        order = self.startedOrderList[index];
        return order;
    }
    index -= self.startedOrderList.count;

    order = self.dealtOrderList[index];
    return order;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.finishedOrderList.count + self.startedOrderList.count + self.dealtOrderList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYOrderViewCell *cell =
    (JYOrderViewCell *)[tableView dequeueReusableCellWithIdentifier:kOrderCellIdentifier forIndexPath:indexPath];

    JYInvite *order = [self _orderAt:indexPath];
    cell.order = order;
    cell.color = order.paymentStatusColor;

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYInvite *order = [self _orderAt:indexPath];
    return [JYOrderViewCell heightForOrder:order];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

#pragma mark - UIActionSheetDelegate

-(void)customActionSheet:(UICustomActionSheet *)customActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{

}

#pragma mark - Network

- (void)_fetchOrders
{
    if (self.networkThreadCount > 0)
    {
        return;
    }

    [self _fetchFinishedOrders];
    [self _fetchStartedOrders];
    [self _fetchDealtOrders];
}

- (void)_fetchStartedOrders
{
    [self networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/my"];
    NSDictionary *parameters = @{@"status": @(JYInviteStatusStarted)};

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"my dealt orders fetch success responseObject: %@", responseObject);

             weakSelf.startedOrderList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 JYInvite *newOrder = [[JYInvite alloc] initWithDictionary:dict];
                 [weakSelf.startedOrderList addObject:newOrder];
             }

             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];
}

- (void)_fetchDealtOrders
{
    [self networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/my"];
    NSDictionary *parameters = @{@"status": @(JYInviteStatusDealt)};

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"my dealt orders fetch success responseObject: %@", responseObject);

             weakSelf.dealtOrderList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 JYInvite *newOrder = [[JYInvite alloc] initWithDictionary:dict];
                 [weakSelf.dealtOrderList addObject:newOrder];
             }

             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];
}

- (void)_fetchFinishedOrders
{
    [self networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/my"];
    NSDictionary *parameters = @{@"status": @(JYInviteStatusFinished)};

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"my finished orders fetch success responseObject: %@", responseObject);

             weakSelf.finishedOrderList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 JYInvite *newOrder = [[JYInvite alloc] initWithDictionary:dict];
                 [weakSelf.finishedOrderList addObject:newOrder];
             }

             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];
}

@end
