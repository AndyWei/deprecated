//
//  JYOrdersBidsViewController.h
//  joyyios
//
//  Created by Ping Yang on 7/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYBaseViewController.h"
#import "JYPaymentViewController.h"
#import "UICustomActionSheet.h"

@import PassKit;

@interface JYOrdersBidsViewController : JYBaseViewController <JYPaymentViewControllerDelegate, PKPaymentAuthorizationViewControllerDelegate, UICustomActionSheetDelegate, UITableViewDataSource, UITableViewDelegate>

@end
