//
//  JYSignUpViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/28/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYButton.h"
#import "JYFloatLabeledTextField.h"
#import "JYSignUpViewController.h"

@interface JYSignUpViewController ()

@end

@implementation JYSignUpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Create Account", nil);

    self.signButton.textLabel.text = NSLocalizedString(@"Sign Up", nil);

    [self.signButton addTarget:self action:@selector(_signUp) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)signButtonTouched
{
    [self _signUp];
}

- (void)_signUp
{
    NSLog(@"Sign up called!!!");
}

@end
