//
//  JYOrdersUnpaidViewController.h
//  joyyios
//
//  Created by Ping Yang on 4/25/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYOrdersBaseViewController.h"

@import PassKit;

@interface JYOrdersUnpaidViewController : JYOrdersBaseViewController <UITableViewDataSource, UITableViewDelegate, PKPaymentAuthorizationViewControllerDelegate>

@end
