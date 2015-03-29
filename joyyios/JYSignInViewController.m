//
//  JYSignInViewController.m
//  joyy
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

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
    NSLog(@"Sign in called!!!");
}

@end
