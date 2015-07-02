//
//  JYOrdersHistoryViewController.m
//  joyyios
//
//  Created by Ping Yang on 7/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>

#import "JYOrdersHistoryViewController.h"
#import "JYOrderViewCell.h"
#import "JYUser.h"

@interface JYOrdersHistoryViewController ()

@end


static NSString *const kOrderCellIdentifier = @"orderCell";

@implementation JYOrdersHistoryViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"HISTORY", nil);

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
    self.tableView.backgroundColor = FlatWhite;
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.orderList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYOrderViewCell *cell =
    (JYOrderViewCell *)[tableView dequeueReusableCellWithIdentifier:kOrderCellIdentifier forIndexPath:indexPath];

    cell.order = self.orderList[indexPath.row];
    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYOrder *order = self.orderList[indexPath.row];
    return [JYOrderViewCell heightForOrder:order];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Network

- (void)_fetchOrders
{
    [self _fetchPaidOrders:NO];
}

- (void)_fetchPaidOrders:(BOOL)loadMore
{
    if (self.networkThreadCount > 0)
    {
        return;
    }

    [self networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/my"];
    NSDictionary *parameters = [self _httpParametersForPaidOrders:loadMore];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"orders/my paid fetch success responseObject: %@", responseObject);

             NSMutableArray *newOrderList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 JYOrder *order = [[JYOrder alloc] initWithDictionary:dict];
                 [newOrderList addObject:order];
             }

             if (newOrderList.count > 0)
             {
                 if (loadMore)
                 {
                     [weakSelf.orderList addObjectsFromArray:newOrderList];
                 }
                 else
                 {
                     [newOrderList addObjectsFromArray:weakSelf.orderList];
                     weakSelf.orderList = newOrderList;
                 }
             }

             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];

}

- (NSDictionary *)_httpParametersForPaidOrders:(BOOL)loadMore
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    [parameters setObject:@(JYOrderStatusPaid) forKey:@"status"];

    if (self.orderList.count > 0)
    {
        if (loadMore)
        {
            JYOrder *oldestOrder = self.orderList.lastObject;
            [parameters setObject:@(oldestOrder.orderId) forKey:@"before"];
        }
        else
        {
            JYOrder *newestOrder = self.orderList.firstObject;
            [parameters setObject:@(newestOrder.orderId) forKey:@"after"];
        }
    }
    return parameters;
}

@end
