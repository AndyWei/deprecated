//
//  JYAccountBaseViewController.h
//  joyyor
//
//  Created by Ping Yang on 6/10/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <XLForm/XLFormViewController.h>

@interface JYAccountBaseViewController : XLFormViewController

@property(nonatomic) NSDictionary *currentAddress;

- (void)createForm;
- (NSString *)submitAccountInfoURL;
- (NSDictionary *)submitAccountInfoParameters;

@end