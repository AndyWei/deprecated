//
//  JYOrdersTodoViewController.m
//  joyyor
//
//  Created by Ping Yang on 5/3/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "AppDelegate.h"
#import "JYOrdersTodoViewController.h"
#import "JYOrderViewCell.h"
#import "JYUser.h"

@interface JYOrdersTodoViewController ()

@property(nonatomic) NSInteger selectedRow;

@end


static NSString *const kOrderCellIdentifier = @"orderCell";

@implementation JYOrdersTodoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitleText:NSLocalizedString(@"Orders Toto", nil)];

    self.selectedRow = -1;
    [self _createTableView];
    [self _fetchData];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fetchData) name:kNotificationBidAccepted object:nil];
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
    self.tableView.backgroundColor = FlatWhite;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[JYOrderViewCell class] forCellReuseIdentifier:kOrderCellIdentifier];
    [self.view addSubview:self.tableView];

    // Add UIRefreshControl
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;

    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(_fetchData) forControlEvents:UIControlEventValueChanged];

    tableViewController.refreshControl = self.refreshControl;

    // Enable scroll to top
    self.scrollView = self.tableView;
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
    [cell presentOrder:order];

    return cell;
}

#pragma mark - override methods

- (void)showActionSheetForOrder:(JYOrder *)order highlightView:(UIView *)view
{
    NSString *actionString = nil;
    switch (order.status)
    {
        case JYOrderStatusPending:
            actionString = NSLocalizedString(@"Start work", nil);
            break;
        case JYOrderStatusOngoing:
            actionString = NSLocalizedString(@"Finish work", nil);
            break;
        default:
            break;
    }

    if (actionString == nil)
    {
        return;
    }

    self.tabBarController.tabBar.hidden = YES;

    UICustomActionSheet *actionSheet = [[UICustomActionSheet alloc] initWithTitle:nil delegate:self buttonTitles:@[NSLocalizedString(@"Cancel", nil), actionString]];

    [actionSheet setButtonColors:@[JoyyBlue50, JoyyBlue, FlatLime]];
    [actionSheet setButtonsTextColor:JoyyWhite];
    actionSheet.backgroundColor = JoyyWhite;

    // Highlight the selected itemView
    CGRect frame = view.frame;
    frame.origin.y -= self.tableView.contentOffset.y;
    actionSheet.clearArea = frame;

    [actionSheet showInView:self.view];
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

    switch (order.status)
    {
        case JYOrderStatusPending:
            [self _updateOrder:order workingStatus:JYOrderStatusOngoing];
            break;
        case JYOrderStatusOngoing:
            [self _updateOrder:order workingStatus:JYOrderStatusFinished];
            break;
        default:
            break;
    }

    self.selectedRow = -1;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [JYOrderViewCell cellHeightForOrder:self.orderList[indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedRow = indexPath.row;

    JYOrder *order = self.orderList[indexPath.row];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self showActionSheetForOrder:order highlightView:cell];

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Network

- (void)_fetchData
{
    if (self.networkThreadCount > 0)
    {
        return;
    }
    [self networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/won"];

     __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"orders/won fetch success responseObject: %@", responseObject);

             weakSelf.orderList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 JYOrder *newOrder = [[JYOrder alloc] initWithDictionary:dict];
                 [weakSelf.orderList addObject:newOrder];  // won orders are in DESC, so just add
             }

             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];
}

- (void)_updateOrder:(JYOrder *)order workingStatus:(JYOrderStatus)status
{
    [self networkThreadBegin];

    NSDictionary *parameters = @{@"order_id": @(order.orderId), @"status": @(status)};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/working_status"];
    __weak typeof(self) weakSelf = self;
    [manager POST:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"orders/working_status success responseObject: %@", responseObject);

             order.status = (JYOrderStatus)[[responseObject objectForKey:@"status"] unsignedIntegerValue];

             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];
}

@end
