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
#import "JYInvite.h"
#import "JYOrderCard.h"
#import "JYOrdersEngagedViewController.h"
#import "JYUser.h"


@interface JYOrdersEngagedViewController ()

@end

static NSString *const kCommentCellIdentifier = @"commentCell";

@implementation JYOrdersEngagedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Engaged", nil);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBidAccepted) name:kNotificationBidAccepted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBidCreated) name:kNotificationDidCreateBid object:nil];
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

- (void)_presentBidViewForOrder:(JYInvite *)order
{
    JYBidCreateViewController *bidViewController = [JYBidCreateViewController new];
    bidViewController.order = order;

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:bidViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)_presentCommentViewForOrder:(JYInvite *)order replyTo:(NSInteger)originCommentIndex
{
    JYCommentsViewController *viewController = [[JYCommentsViewController alloc] initWithOrder:order];
    viewController.originalCommentIndex = originCommentIndex;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)onBidAccepted
{
    [self fetchOrders];
}

- (void)onBidCreated
{
    [self fetchOrders];
}

- (void)onCommentCreated
{
    [self fetchOrders];
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYInvite *order = self.orderList[indexPath.section];

    [self _presentCommentViewForOrder:order replyTo:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    JYInvite *order = self.orderList[section];
    return [JYOrderCard heightForOrder:order withAddress:NO andBid:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    JYInvite *order = self.orderList[section];
    CGFloat height = [JYOrderCard heightForOrder:order withAddress:NO andBid:YES];

    JYOrderCard *card = [[JYOrderCard alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), height)];

    // make the order item view tappable
    card.tag = section;
    [card addTarget:self action: @selector(tapOnTableSectionHeader:) forControlEvents:UIControlEventTouchUpInside];

    // show order
    card.tinyLabelsHidden = NO;
    [card presentOrder:order withAddress:NO andBid:YES];
    card.backgroundColor = order.bidColor;

    return card;
}

#pragma mark - UIActionSheetDelegate

-(void)customActionSheet:(UICustomActionSheet *)customActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.tabBarController.tabBar.hidden = NO;
    if (self.selectedSection < 0)
    {
        return;
    }

    JYInvite *order = self.orderList[self.selectedSection];

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

- (NSString *)fetchOrdersURL
{
    return [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/engaged"];
}

@end
