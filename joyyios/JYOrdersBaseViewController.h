//
//  JYOrdersBaseViewController.h
//  joyyios
//
//  Created by Ping Yang on 5/25/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYExpandViewController.h"
#import "JYOrder.h"
#import "UICustomActionSheet.h"

@interface JYOrdersBaseViewController : JYExpandViewController <UICustomActionSheetDelegate>

- (void)networkThreadBegin;
- (void)networkThreadEnd;
- (void)showActionSheetForOrder:(JYOrder *)order highlightView:(UIView *)view;
- (void)fetchMyBids;
- (void)fetchComments;

- (JYOrder *)orderOfId:(NSUInteger)targetOrderId;

@property(nonatomic) NSInteger networkThreadCount;
@property(nonatomic) NSMutableArray *orderList;
@property(nonatomic) UITableView *tableView;
@property(nonatomic) UIRefreshControl *refreshControl;


@end
