//
//  JYOrdersFinishedViewController.m
//  joyyios
//
//  Created by Ping Yang on 6/21/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>

#import "JYOrdersFinishedViewController.h"
#import "JYOrderViewCell.h"
#import "JYUser.h"

@interface JYOrdersFinishedViewController ()

@property(nonatomic) NSMutableArray *unpaidOrderList;
@property(nonatomic) NSMutableArray *paidOrderList;

@end


static NSString *const kOrderCellIdentifier = @"orderCell";

@implementation JYOrdersFinishedViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitleText:NSLocalizedString(@"Finished Orders", nil)];

    self.unpaidOrderList = [NSMutableArray new];
    self.paidOrderList = [NSMutableArray new];

    [self _createTableView];
    [self _fetchAllOrders];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fetchUnpaidOrders) name:kNotificationDidFinishOrder object:nil];
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
    [self.tableView registerClass:[JYOrderViewCell class] forCellReuseIdentifier:kOrderCellIdentifier];
    [self.view addSubview:self.tableView];

    // Add UIRefreshControl
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;

    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(_fetchAllOrders) forControlEvents:UIControlEventValueChanged];

    tableViewController.refreshControl = self.refreshControl;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (section == 0) ? self.unpaidOrderList.count : self.paidOrderList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYOrderViewCell *cell =
    (JYOrderViewCell *)[tableView dequeueReusableCellWithIdentifier:kOrderCellIdentifier forIndexPath:indexPath];

    cell.order = (indexPath.section == 0) ? self.unpaidOrderList[indexPath.row] : self.paidOrderList[indexPath.row];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYOrder *order = (indexPath.section == 0) ? self.unpaidOrderList[indexPath.row] : self.paidOrderList[indexPath.row];
    return [JYOrderViewCell cellHeightForOrder:order];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerLabel = [self _createLabel];

    if (section == 0)
    {
        NSString *youHave = NSLocalizedString(@"You have", nil);
        NSString *unpaidOrders = NSLocalizedString(@"unpaid orders", nil);
        headerLabel.text = [NSString stringWithFormat:@"%@ %tu %@", youHave, self.unpaidOrderList.count, unpaidOrders];
    }
    else
    {
        headerLabel.text = NSLocalizedString(@"Paid Orders", nil);
    }

    return headerLabel;
}

- (UILabel *)_createLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 50)];
    label.font = [UIFont systemFontOfSize:22];
    label.backgroundColor = FlatWhite;
    label.textColor = FlatBlack;
    label.textAlignment = NSTextAlignmentCenter;

    return label;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    self.selectedIndexPath = indexPath;
//    self.tabBarController.tabBar.hidden = YES;
//
//    UICustomActionSheet *actionSheet = [[UICustomActionSheet alloc] initWithTitle:nil delegate:self buttonTitles:@[NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Accept", nil)]];
//
//    [actionSheet setButtonColors:@[JoyyBlue50, JoyyBlue]];
//    [actionSheet setButtonsTextColor:JoyyWhite];
//    actionSheet.backgroundColor = JoyyWhite;
//
//    // Highlight the selected cell
//    CGRect frame = [tableView cellForRowAtIndexPath:indexPath].frame;
//    frame.origin.y -= tableView.contentOffset.y;
//    actionSheet.clearArea = frame;
//
//    [actionSheet showInView:self.view];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Network

- (void)_fetchAllOrders
{
    [self _fetchUnpaidOrders];
    [self _fetchPaidOrders:NO];
}

- (void)_fetchUnpaidOrders
{
    [self networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/my"];
    NSDictionary *parameters = @{@"status": @(JYOrderStatusFinished)};

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"orders/my finished fetch success responseObject: %@", responseObject);

             weakSelf.unpaidOrderList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 JYOrder *order = [[JYOrder alloc] initWithDictionary:dict];
                 [weakSelf.unpaidOrderList addObject:order];
             }

             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];
}

- (void)_fetchPaidOrders:(BOOL)loadMore
{
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
                     [weakSelf.paidOrderList addObjectsFromArray:newOrderList];
                 }
                 else
                 {
                     [newOrderList addObjectsFromArray:weakSelf.paidOrderList];
                     weakSelf.paidOrderList = newOrderList;
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

    if (self.paidOrderList.count > 0)
    {
        if (loadMore)
        {
            JYOrder *oldestOrder = self.paidOrderList.lastObject;
            [parameters setObject:@(oldestOrder.orderId) forKey:@"before"];
        }
        else
        {
            JYOrder *newestOrder = self.paidOrderList.firstObject;
            [parameters setObject:@(newestOrder.orderId) forKey:@"after"];
        }
    }
    return parameters;
}
@end

