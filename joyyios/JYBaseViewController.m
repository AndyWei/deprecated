//
//  JYBaseViewController.m
//  joyyios
//
//  Created by Ping Yang on 7/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYBaseViewController.h"

@interface JYBaseViewController ()

@end

@implementation JYBaseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.needReloadTable = NO;
    self.networkThreadCount = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
        if (self.needReloadTable)
        {
            self.needReloadTable = NO;
            [self.tableView reloadData];
        }

    }
}

- (JYInvite *)orderOfId:(NSUInteger)targetOrderId
{
    for (JYInvite *order in self.orderList)
    {
        if (order.orderId == targetOrderId)
        {
            return order;
        }
    }
    return nil;
}

@end
