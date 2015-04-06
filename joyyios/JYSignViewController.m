//
//  JYSignViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <EAIntroView/EAIntroView.h>

#import "JYButton.h"
#import "JYSignInViewController.h"
#import "JYSignUpViewController.h"
#import "JYSignViewController.h"

@interface JYSignViewController ()
{
    JYButton *_signInButton;
    JYButton *_signUpButton;
    UIView *_partingLineH;
    UIView *_partingLineV;
}
@end

@implementation JYSignViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = JoyyBlue;

    // Set the navigationBar to be transparent
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;

    [self _createSignInButton];
    [self _createSignUpButton];
    [self _createPartingLines];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_createSignInButton
{
    CGRect frame = CGRectMake(0,
                              CGRectGetHeight(self.view.frame) - kSignButtonHeight,
                              CGRectGetMidX(self.view.frame),
                              kSignButtonHeight);

    _signInButton = [[JYButton alloc] initWithFrame:frame buttonStyle:JYButtonStyleDefault];
    _signInButton.backgroundColor = ClearColor;
    _signInButton.contentAnimateToColor = FlatBlack;
    _signInButton.contentColor = FlatWhite;
    _signInButton.foregroundColor = ClearColor;
    _signInButton.foregroundAnimateToColor = FlatWhite;
    _signInButton.textLabel.font = [UIFont systemFontOfSize:kSignFieldFontSize];
    _signInButton.textLabel.text = NSLocalizedString(@"Sign In", nil);

    [_signInButton addTarget:self action:@selector(_signIn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_signInButton];
}

- (void)_createSignUpButton
{
    CGRect frame = CGRectMake(CGRectGetMidX(self.view.frame),
                              CGRectGetHeight(self.view.frame) - kSignButtonHeight,
                              CGRectGetMidX(self.view.frame),
                              kSignButtonHeight);

    _signUpButton = [[JYButton alloc] initWithFrame:frame buttonStyle:JYButtonStyleDefault];
    _signUpButton.backgroundColor = ClearColor;
    _signUpButton.contentAnimateToColor = FlatBlack;
    _signUpButton.contentColor = FlatWhite;
    _signUpButton.foregroundColor = ClearColor;
    _signUpButton.foregroundAnimateToColor = FlatWhite;
    _signUpButton.textLabel.font = [UIFont systemFontOfSize:kSignFieldFontSize];
    _signUpButton.textLabel.text = NSLocalizedString(@"Sign Up", nil);

    [_signUpButton addTarget:self action:@selector(_signUp) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_signUpButton];
}

- (void)_createPartingLines
{
    CGFloat y = CGRectGetHeight(self.view.frame) - kSignButtonHeight;
    _partingLineH = [UIView new];
    _partingLineH.frame = CGRectMake(0, y, CGRectGetWidth(self.view.frame), 0.5f);
    _partingLineH.backgroundColor = FlatWhite;
    [self.view addSubview:_partingLineH];

    _partingLineV = [UIView new];
    _partingLineV.frame = CGRectMake(CGRectGetMidX(self.view.frame), y, 1.0f, kSignButtonHeight);
    _partingLineV.backgroundColor = FlatWhite;
    [self.view addSubview:_partingLineV];
}

- (void)_signIn
{
    JYSignInViewController *viewController = [JYSignInViewController new];
    [self.navigationController pushViewController:viewController animated:NO];
}

- (void)_signUp
{
    JYSignUpViewController *viewController = [JYSignUpViewController new];
    [self.navigationController pushViewController:viewController animated:NO];
}

@end
