//
//  JYSignBaseViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JVFloatLabeledTextField.h"
#import "JVFloatLabeledTextView.h"
#import "JYSignBaseViewController.h"

@interface JYSignBaseViewController ()

@end

@implementation JYSignBaseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Sign In", @"");
    self.view.tintColor = FlatSkyBlue;

    CGFloat topOffset = 2 * ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height);


    UIColor *floatingLabelColor = FlatGreen;

    JVFloatLabeledTextField *emailField = [[JVFloatLabeledTextField alloc] initWithFrame:
                                           CGRectMake(kJVFieldXMargin,
                                                      topOffset,
                                                      self.view.frame.size.width - 2 * kJVFieldXMargin,
                                                      kJVFieldHeight)];

    emailField.attributedPlaceholder = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"Email", @"")attributes: @{NSForegroundColorAttributeName: FlatGrayDark}];
    emailField.font = [UIFont systemFontOfSize: kJVFieldFontSize];
    emailField.floatingLabel.font = [UIFont systemFontOfSize:kJVFieldFloatingLabelFontSize];
    emailField.floatingLabelTextColor = floatingLabelColor;
    emailField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:emailField];

    UIView *emailView = [UIView new];
    emailView.frame = CGRectMake(kJVFieldXMargin, emailField.frame.origin.y + emailField.frame.size.height,
                                 self.view.frame.size.width - 2 * kJVFieldXMargin, 1.0f);
    emailView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3f];
    [self.view addSubview:emailView];

    JVFloatLabeledTextField *passwordField = [[JVFloatLabeledTextField alloc] initWithFrame:
                                              CGRectMake(kJVFieldXMargin,
                                                         emailView.frame.origin.y + emailView.frame.size.height,
                                                         self.view.frame.size.width - 2 * kJVFieldXMargin,
                                                         kJVFieldHeight)];

    passwordField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Password", @"") attributes:@{NSForegroundColorAttributeName: FlatGray}];
    passwordField.font = [UIFont systemFontOfSize:kJVFieldFontSize];
    passwordField.floatingLabel.font = [UIFont systemFontOfSize:kJVFieldFloatingLabelFontSize];
    passwordField.floatingLabelTextColor = floatingLabelColor;
    passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:passwordField];

    [emailField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
