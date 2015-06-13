//
//  JYAccountBaseViewController.m
//  joyyor
//
//  Created by Ping Yang on 6/10/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYAccountBaseViewController.h"
#import "JYButton.h"
#import "JYUser.h"

@interface JYAccountBaseViewController ()

@end

@implementation JYAccountBaseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *barButton =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Submit", nil) style:UIBarButtonItemStylePlain target:self action:@selector(_submit)];
    self.navigationItem.rightBarButtonItem = barButton;

    [self createForm];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)createForm
{
    NSAssert(NO, @"This method should be overriden by subclass");
}

- (NSString *)submitAccountInfoURL
{
    NSAssert(NO, @"This method should be overriden by subclass");
    return nil;
}

- (NSDictionary *)submitAccountInfoParameters
{
    NSAssert(NO, @"This method should be overriden by subclass");
    return nil;
}

- (BOOL)_formFilled
{
    if (!self.form)
    {
        return NO;
    }

    NSArray *validationErrors = [self formValidationErrors];
    if (validationErrors == NULL || validationErrors.count == 0)
    {
        return YES;

    }

    [self _showFormValidationError:[validationErrors firstObject]];
    return NO;
}

- (void)_showFormValidationError:(NSError *)error
{
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(kErrorTitle, nil) message:error.localizedDescription delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alertView show];
}

- (void)_submit
{
    if ([self _formFilled])
    {
        [self _submitAccountInfo];
    }
}

- (void)_submitAccountInfo
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [self submitAccountInfoURL];

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:[self submitAccountInfoParameters]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"Account Create Success responseObject: %@", responseObject);

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress showSuccessWithStatus:NSLocalizedString(@"Account Created!", nil)];

              [JYUser currentUser].joyyorStatus = 1;
              [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidCreateAccount object:nil];
              [weakSelf.navigationController popToRootViewControllerAnimated:NO];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress dismiss];

              NSString *errorMessage = NSLocalizedString(@"Can't create the account due to network failure, please retry later", nil);
              [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                             message:errorMessage
                     backgroundColor:FlatYellow
                           textColor:FlatBlack
                                time:5];
              
          }
     ];
}

@end
