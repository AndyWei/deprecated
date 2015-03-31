//
//  JYSignViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <EAIntroView/EAIntroView.h>

#import "JYSignInViewController.h"
#import "JYSignUpViewController.h"
#import "JYSignViewController.h"
#import "MRoundedButton.h"

@interface JYSignViewController ()
{
    MRoundedButton *_signInButton;
    MRoundedButton *_signUpButton;
}
@end

@implementation JYSignViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = FlatSkyBlue;
    [self _createSignInButton];
    [self _createSignUpButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_createSignInButton
{
    CGRect frame = CGRectMake(0,
                              self.view.frame.size.height - kSignButtonHeight,
                              self.view.frame.size.width / 2,
                              kSignButtonHeight);

    _signInButton = [[MRoundedButton alloc] initWithFrame:frame buttonStyle:MRoundedButtonDefault];
    _signInButton.backgroundColor = ClearColor;
    _signInButton.borderColor = FlatWhite;
    _signInButton.borderWidth = 0.5f;
    _signInButton.contentAnimateToColor = FlatBlack;
    _signInButton.contentColor = FlatWhite;
    _signInButton.foregroundColor = ClearColor;
    _signInButton.foregroundAnimateToColor = FlatWhite;
    _signInButton.textLabel.font = [UIFont boldSystemFontOfSize:kSignFieldFontSize];
    _signInButton.textLabel.text = NSLocalizedString(@"Sign In", nil);

    [_signInButton addTarget:self action:@selector(_signIn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_signInButton];
}

- (void)_createSignUpButton
{
    CGRect frame = CGRectMake(self.view.frame.size.width / 2,
                              self.view.frame.size.height - kSignButtonHeight,
                              self.view.frame.size.width / 2,
                              kSignButtonHeight);

    _signUpButton = [[MRoundedButton alloc] initWithFrame:frame buttonStyle:MRoundedButtonDefault];
    _signUpButton.backgroundColor = ClearColor;
    _signUpButton.borderColor = FlatWhite;
    _signUpButton.borderWidth = 0.5f;
    _signUpButton.contentAnimateToColor = FlatBlack;
    _signUpButton.contentColor = FlatWhite;
    _signUpButton.foregroundColor = ClearColor;
    _signUpButton.foregroundAnimateToColor = FlatWhite;
    _signUpButton.textLabel.font = [UIFont boldSystemFontOfSize:kSignFieldFontSize];
    _signUpButton.textLabel.text = NSLocalizedString(@"Sign Up", nil);

    [_signUpButton addTarget:self action:@selector(_signUp) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_signUpButton];
}

- (void)_signIn
{
    JYSignInViewController *viewController = [JYSignInViewController new];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)_signUp
{
    JYSignUpViewController *viewController = [JYSignUpViewController new];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
