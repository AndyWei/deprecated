//
//  JYBaseViewController.h
//  joyyios
//
//  Created by Ping Yang on 7/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYInvite.h"

@interface JYBaseViewController : UIViewController

- (JYInvite *)orderOfId:(NSUInteger)targetOrderId;
- (void)networkThreadBegin;
- (void)networkThreadEnd;

@property(nonatomic) BOOL needReloadTable;
@property(nonatomic) NSInteger networkThreadCount;
@property(nonatomic) NSMutableArray *orderList;
@property(nonatomic) UITableView *tableView;
@property(nonatomic) UIRefreshControl *refreshControl;

@end
