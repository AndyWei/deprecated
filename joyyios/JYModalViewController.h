//
//  JYModalViewController.h
//  joyyios
//
//  Created by Ping Yang on 7/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYOrder.h"

@interface JYModalViewController : UIViewController

- (JYOrder *)orderOfId:(NSUInteger)targetOrderId;
- (void)networkThreadBegin;
- (void)networkThreadEnd;

@property(nonatomic) NSInteger networkThreadCount;
@property(nonatomic) NSMutableArray *orderList;
@property(nonatomic) UITableView *tableView;
@property(nonatomic) UIRefreshControl *refreshControl;

@end
