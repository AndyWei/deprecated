//
//  JYSignViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYButton.h"
#import "JYSignInViewController.h"
#import "JYSignUpViewController.h"
#import "JYSignViewController.h"

@interface JYSignViewController ()

@property(nonatomic) JYButton *signInButton;
@property(nonatomic) JYButton *signUpButton;
@property(nonatomic) UIView *partingLineH;
@property(nonatomic) UIView *partingLineV;

@end


@implementation JYSignViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = FlatGrayDark;

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

    self.signInButton = [[JYButton alloc] initWithFrame:frame buttonStyle:JYButtonStyleTitle];
    self.signInButton.backgroundColor = ClearColor;
    self.signInButton.contentAnimateToColor = FlatBlack;
    self.signInButton.contentColor = FlatWhite;
    self.signInButton.foregroundColor = FlatGreen;
    self.signInButton.foregroundAnimateToColor = FlatWhite;
    self.signInButton.textLabel.font = [UIFont systemFontOfSize:kSignFieldFontSize];
    self.signInButton.textLabel.text = NSLocalizedString(@"Sign In", nil);

    [self.signInButton addTarget:self action:@selector(_signIn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.signInButton];
}

- (void)_createSignUpButton
{
    CGRect frame = CGRectMake(CGRectGetMidX(self.view.frame),
                              CGRectGetHeight(self.view.frame) - kSignButtonHeight,
                              CGRectGetMidX(self.view.frame),
                              kSignButtonHeight);

    self.signUpButton = [[JYButton alloc] initWithFrame:frame buttonStyle:JYButtonStyleTitle];
    self.signUpButton.backgroundColor = ClearColor;
    self.signUpButton.contentAnimateToColor = FlatBlack;
    self.signUpButton.contentColor = FlatWhite;
    self.signUpButton.foregroundColor = FlatSkyBlue;
    self.signUpButton.foregroundAnimateToColor = FlatWhite;
    self.signUpButton.textLabel.font = [UIFont systemFontOfSize:kSignFieldFontSize];
    self.signUpButton.textLabel.text = NSLocalizedString(@"I'm New", nil);

    [self.signUpButton addTarget:self action:@selector(_signUp) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.signUpButton];
}

- (void)_createPartingLines
{
    CGFloat y = CGRectGetHeight(self.view.frame) - kSignButtonHeight;
    self.partingLineH = [UIView new];
    self.partingLineH.frame = CGRectMake(0, y, CGRectGetWidth(self.view.frame), 0.5f);
    self.partingLineH.backgroundColor = FlatWhite;
    [self.view addSubview:self.partingLineH];

    self.partingLineV = [UIView new];
    self.partingLineV.frame = CGRectMake(CGRectGetMidX(self.view.frame), y, 1.0f, kSignButtonHeight);
    self.partingLineV.backgroundColor = FlatWhite;
    [self.view addSubview:self.partingLineV];
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
