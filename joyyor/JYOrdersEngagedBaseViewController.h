//
//  JYOrdersEngagedBaseViewController.h
//  joyyor
//
//  Created by Ping Yang on 6/16/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYOrdersBaseViewController.h"

@interface JYOrdersEngagedBaseViewController : JYOrdersBaseViewController <UITableViewDataSource, UITableViewDelegate>

@property(nonatomic) NSInteger selectedSection;

- (void)tapOnTableSectionHeader:(id)sender;
- (void)fetchOrders;
- (NSString *)fetchOrdersURL;

@end