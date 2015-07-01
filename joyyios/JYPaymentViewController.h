//
//  JYPaymentViewController.h
//  joyyios
//
//  Created by Ping Yang on 6/18/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

#import "JYModalViewController.h"

@class JYPaymentViewController;

@protocol JYPaymentViewControllerDelegate <NSObject>

- (void)viewController:(JYPaymentViewController *)controller didCreateToken:(NSString *)token;
- (void)viewControllerDidFinish:(JYPaymentViewController *)controller;

@end


@interface JYPaymentViewController : JYModalViewController

@property(nonatomic, weak) NSMutableArray *creditCardList;
@property(nonatomic, weak) id<JYPaymentViewControllerDelegate> delegate;

@end
