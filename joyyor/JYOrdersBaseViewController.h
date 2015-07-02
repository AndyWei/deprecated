//
//  JYOrdersBaseViewController.h
//  joyyios
//
//  Created by Ping Yang on 5/25/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYModalViewController.h"
#import "JYOrder.h"
#import "UICustomActionSheet.h"

@interface JYOrdersBaseViewController : JYModalViewController <UICustomActionSheetDelegate>

- (void)showActionSheetForOrder:(JYOrder *)order highlightView:(UIView *)view;
- (void)fetchComments;
- (void)fetchMyBids;
- (NSDictionary *)fetchMyBidsParameters;

@end
