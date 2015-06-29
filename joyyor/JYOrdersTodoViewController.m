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
#import "JYCommentViewCell.h"
#import "JYOrdersTodoViewController.h"
#import "JYOrderCard.h"
#import "JYUser.h"

@interface JYOrdersTodoViewController ()

@end


@implementation JYOrdersTodoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitleText:NSLocalizedString(@"Orders Toto", nil)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBidAccepted) name:kNotificationBidAccepted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCommentCreated) name:kNotificationDidCreateComment object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onBidAccepted
{
    [self fetchOrders];
}

- (void)onCommentCreated
{
    [self fetchOrders];
}

#pragma mark - override methods

- (void)showActionSheetForOrder:(JYOrder *)order highlightView:(UIView *)view
{
    NSString *actionString = nil;
    switch (order.status)
    {
        case JYOrderStatusDealt:
            actionString = NSLocalizedString(@"Start work", nil);
            break;
        case JYOrderStatusStarted:
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

    // Highlight the selected card
    CGRect frame = view.frame;
    frame.origin.y -= self.tableView.contentOffset.y;
    actionSheet.clearArea = frame;

    [actionSheet showInView:self.view];
}

#pragma mark - UIActionSheetDelegate

- (void)customActionSheet:(UICustomActionSheet *)customActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.tabBarController.tabBar.hidden = NO;

    if (buttonIndex == 0) // cancel
    {
        self.selectedSection = -1;
        return;
    }

    if (self.selectedSection < 0)
    {
        return;
    }

    JYOrder *order = self.orderList[self.selectedSection];
    NSString *url = nil;
    switch (order.status)
    {
        case JYOrderStatusDealt:
            url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/started"];
            [self _updateOrder:order withURL:url];
            break;
        case JYOrderStatusStarted:
            url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/finished"];
            [self _updateOrder:order withURL:url];
            break;
        default:
            break;
    }

    self.selectedSection = -1;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    JYOrder *order = self.orderList[section];
    return [JYOrderCard cardHeightForOrder:order withAddress:YES andBid:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    JYOrder *order = self.orderList[section];
    CGFloat height = [JYOrderCard cardHeightForOrder:order withAddress:YES andBid:YES];

    JYOrderCard *card = [[JYOrderCard alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), height)];

    // make the order item view tappable
    card.tag = section;
    [card addTarget:self action: @selector(tapOnTableSectionHeader:) forControlEvents:UIControlEventTouchUpInside];

    // show order
    card.tinyLabelsHidden = NO;
    [card presentOrder:order withAddress:YES andBid:YES];
    card.backgroundColor = order.workingStatusColor;

    return card;
}

#pragma mark - Network

- (NSString *)fetchOrdersURL
{
    return [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/won"];
}

- (NSDictionary *)fetchMyBidsParameters
{
    NSDictionary *parameters = @{@"status": @(JYBidStatusAccepted)};
    return parameters;
}

- (void)_updateOrder:(JYOrder *)order withURL:(NSString *)url
{
    [self networkThreadBegin];

    NSDictionary *parameters = @{@"order_id": @(order.orderId)};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    __weak typeof(self) weakSelf = self;
    [manager POST:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"orders/update success responseObject: %@", responseObject);

             order.status = (JYOrderStatus)[[responseObject objectForKey:@"status"] unsignedIntegerValue];

             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
         }
     ];
}

@end
