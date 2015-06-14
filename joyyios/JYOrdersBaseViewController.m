//
//  JYOrdersBaseViewController.m
//  joyyios
//
//  Created by Ping Yang on 5/25/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "JYBid.h"
#import "JYOrder.h"
#import "JYOrdersBaseViewController.h"
#import "JYUser.h"

@interface JYOrdersBaseViewController ()

@end


@implementation JYOrdersBaseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.maxOrderId = 0;
    self.maxBidId = 0;
    self.networkThreadCount = 0;

    self.orderList = [NSMutableArray new];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    self.orderList = nil;
}

- (JYOrder *)orderOfId:(NSUInteger)targetOrderId
{
    for (JYOrder *order in self.orderList)
    {
        if (order.orderId == targetOrderId)
        {
            return order;
        }
    }
    return nil;
}

- (void)networkThreadBegin
{
    if (self.networkThreadCount == 0)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    self.networkThreadCount++;
}

- (void)networkThreadEnd
{
    self.networkThreadCount--;
    if (self.networkThreadCount <= 0)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self.refreshControl endRefreshing];
        [self.tableView reloadData];
    }
}

- (void)showActionSheetForOrder:(JYOrder *)order highlightView:(UIView *)view
{
    self.tabBarController.tabBar.hidden = YES;

    NSString *bidString = (order.bids.count > 0) ? NSLocalizedString(@"Update Bid", nil) : NSLocalizedString(@"Bid", nil);

    UICustomActionSheet *actionSheet = [[UICustomActionSheet alloc] initWithTitle:nil delegate:self buttonTitles:@[NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Comment", nil), bidString]];

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

-(void)customActionSheet:(UICustomActionSheet *)customActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Do nothing. Subclasses should implement it
}


#pragma mark - Network

- (void)fetchMyBids
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

             NSLog(@"bids/from_me fetch success responseObject: %@", responseObject);
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

@end
