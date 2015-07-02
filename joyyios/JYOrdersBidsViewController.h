//
//  JYOrdersBidsViewController.h
//  joyyios
//
//  Created by Ping Yang on 7/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYModalViewController.h"
#import "JYPaymentViewController.h"
#import "UICustomActionSheet.h"

@import PassKit;

@interface JYOrdersBidsViewController : JYModalViewController <JYPaymentViewControllerDelegate, PKPaymentAuthorizationViewControllerDelegate, UICustomActionSheetDelegate, UITableViewDataSource, UITableViewDelegate>

@end
