//
//  JYModalViewController.m
//  joyyios
//
//  Created by Ping Yang on 7/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYModalViewController.h"

@interface JYModalViewController ()

@end

@implementation JYModalViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.networkThreadCount = 0;

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"DONE" style:UIBarButtonItemStylePlain target:self action:@selector(_done)];
    self.navigationItem.leftBarButtonItem = doneButton;
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
        [self.tableView reloadData];
    }
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

- (void)_done
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
