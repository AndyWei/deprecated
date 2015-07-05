//
//  JYOrdersEngagedBaseViewController.m
//  joyyor
//
//  Created by Ping Yang on 6/16/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "JYBidCreateViewController.h"
#import "JYComment.h"
#import "JYCommentViewCell.h"
#import "JYCommentsViewController.h"
#import "JYInvite.h"
#import "JYOrderCard.h"
#import "JYOrdersEngagedBaseViewController.h"
#import "JYUser.h"


@interface JYOrdersEngagedBaseViewController ()

@end

static NSString *const kCommentCellIdentifier = @"commentCell";

@implementation JYOrdersEngagedBaseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;

    self.selectedSection = -1;

    [self _createTableView];
    [self fetchOrders];
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
    [self.refreshControl addTarget:self action:@selector(fetchOrders) forControlEvents:UIControlEventValueChanged];

    tableViewController.refreshControl = self.refreshControl;

    // Enable scroll to top
//    self.scrollView = self.tableView;
}

- (void)tapOnTableSectionHeader:(id)sender
{
    JYOrderCard *card = (JYOrderCard *)sender;
    self.selectedSection = card.tag;

    JYInvite *order = self.orderList[self.selectedSection];
    [self showActionSheetForOrder:order highlightView:card];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.orderList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    JYInvite *order = self.orderList[section];
    return order.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYCommentViewCell *cell =
    (JYCommentViewCell *)[tableView dequeueReusableCellWithIdentifier:kCommentCellIdentifier forIndexPath:indexPath];

    JYInvite *order = self.orderList[indexPath.section];
    [cell presentComment:order.comments[indexPath.row]];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYInvite *order = self.orderList[indexPath.section];
    return [JYCommentViewCell cellHeightForComment:order.comments[indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Do nothing. Subclasses should implement it
    NSAssert(NO, @"This method is for subclassing only");
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // Do nothing. Subclasses should implement it
    NSAssert(NO, @"This method is for subclassing only");
    return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // Do nothing. Subclasses should implement it
    NSAssert(NO, @"This method is for subclassing only");
    return nil;
}

#pragma mark - UIActionSheetDelegate

-(void)customActionSheet:(UICustomActionSheet *)customActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Do nothing. Subclasses should implement it
    NSAssert(NO, @"This method is for subclassing only");
}

#pragma mark - Network

- (NSString *)fetchOrdersURL
{
    // Do nothing. Subclasses should implement it
    NSAssert(NO, @"This method is for subclassing only");
    return nil;
}

- (void)fetchOrders
{
    if (self.networkThreadCount > 0)
    {
        return;
    }
    [self networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [self fetchOrdersURL];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             //             NSLog(@"orders/engaged fetch success responseObject: %@", responseObject);

             weakSelf.orderList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 JYInvite *newOrder = [[JYInvite alloc] initWithDictionary:dict];
                 [weakSelf.orderList addObject:newOrder];
             }

             if (weakSelf.orderList.count > 0)
             {
                 [weakSelf fetchMyBids];
                 [weakSelf fetchComments];
             }

             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];
}

@end
