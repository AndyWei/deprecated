//
//  JYOrdersBidsViewController.h
//  joyyios
//
//  Created by Ping Yang on 7/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYOrdersBaseViewController.h"
#import "JYPaymentViewController.h"

@import PassKit;

@interface JYOrdersBidsViewController : JYOrdersBaseViewController <UITableViewDataSource, UITableViewDelegate, PKPaymentAuthorizationViewControllerDelegate, JYPaymentViewControllerDelegate>

@end
