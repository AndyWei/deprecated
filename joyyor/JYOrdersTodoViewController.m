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

@end


static NSString *const kOrderCellIdentifier = @"orderCell";

@implementation JYOrdersTodoViewController

+ (UILabel *)sharedSwipeBackgroundLabel
{
    static UILabel *_sharedSwipeBackgroundLabel = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedSwipeBackgroundLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
        _sharedSwipeBackgroundLabel.font = [UIFont systemFontOfSize:25];
        _sharedSwipeBackgroundLabel.text = NSLocalizedString(@"Start", nil);
        _sharedSwipeBackgroundLabel.textColor = [UIColor whiteColor];
        _sharedSwipeBackgroundLabel.textAlignment= NSTextAlignmentCenter;
    });

    return _sharedSwipeBackgroundLabel;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitleText:NSLocalizedString(@"Orders Toto", nil)];

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

    [self _createSwipeViewForCell:cell andOrder:order];
    return cell;
}

- (void)_createSwipeViewForCell:(JYOrderViewCell *)cell andOrder:(JYOrder *)order
{
    __weak typeof(self) weakSelf = self;
    [cell setSwipeGestureWithView:[[self class] sharedSwipeBackgroundLabel]
                            color:FlatGreen
                             mode:MCSwipeTableViewCellModeSwitch
                            state:MCSwipeTableViewCellState3
                  completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
                      [weakSelf _startWorkOn:order];
                  }];

    [cell setDefaultColor:FlatGreen];
    cell.firstTrigger = 0.20;
}

- (void)_startWorkOn:(JYOrder *)order
{

}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [JYOrderViewCell cellHeightForOrder:self.orderList[indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self _startWorkOn:self.orderList[indexPath.row]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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

@end
