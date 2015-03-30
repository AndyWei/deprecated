//
//  JYSignInViewController.m
//  joyy
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "AFNetworking.h"
#import "JYFloatLabeledTextField.h"
#import "JYSignInViewController.h"
#import "MRoundedButton.h"

@interface JYSignInViewController ()

@end

@implementation JYSignInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *signIn = NSLocalizedString(@"Sign In", nil);
    self.title = signIn;

    self.signButton.textLabel.text = signIn;

    [self.signButton addTarget:self action:@selector(_signIn) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)signButtonTouched
{
    [self _signIn];
}

- (void)_signIn
{
    NSString *email = [self.emailField.text lowercaseString];
    NSString *password = [self.passwordField.text lowercaseString];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:email password:password];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlApiBase, @"signin"];

    [manager GET:url parameters:nil
    success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSLog(@"JSON: %@", responseObject);
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"Error: %@", error);
    }];
}

@end
