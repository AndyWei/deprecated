//
//  JYOrdersEngagedViewController.h
//  joyyor
//
//  Created by Ping Yang on 5/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYOrdersBaseViewController.h"

@interface JYOrdersEngagedViewController : JYOrdersBaseViewController <UITableViewDataSource, UITableViewDelegate>

@property(nonatomic) NSInteger selectedSection;

- (void)onCommentCreated;
- (void)tapOnTableSectionHeader:(id)sender;
- (void)fetchOrders;
- (NSString *)fetchOrdersURL;

@end
