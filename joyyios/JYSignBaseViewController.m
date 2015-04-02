//
//  JYSignBaseViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYAutoCompleteDataSource.h"
#import "JYFloatLabeledTextField.h"
#import "JYSignBaseViewController.h"
#import "MRoundedButton.h"

@interface JYSignBaseViewController ()

@property(nonatomic, strong) UIView *partingLine;

@end

@implementation JYSignBaseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.tintColor = JoyyBlue;
    self.navigationController.navigationBar.tintColor = JoyyBlue;

    [self _createEmailField];
    [self _createPartingLine];
    [self _createPasswordField];
    [self _createSignButton];

    [_emailField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchSignButton
{
    _signButton.selected = YES;
    [self signButtonTouched];
    _signButton.selected = NO;
}

- (void)signButtonTouched
{
    NSAssert(NO, @"The signButtonTouched method in the base clasee should never been called");
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _emailField)
    {
        [_emailField resignFirstResponder];
        [_passwordField becomeFirstResponder];
        return NO;
    }
    else if (textField == _passwordField)
    {
        [_passwordField resignFirstResponder];
        [self touchSignButton];
        return NO;
    }

    return YES;
}

#pragma mark - Private Methods

- (void)_createEmailField
{
    _emailField = [[JYFloatLabeledTextField alloc]
        initWithFrame:CGRectMake(kSignFieldMarginLeft, kSignViewTopOffset, self.view.frame.size.width - 2 * kSignFieldMarginLeft, kSignFieldHeight)];

    _emailField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Email", nil) attributes:@{NSForegroundColorAttributeName : FlatGrayDark}];

    _emailField.autocompleteDataSource = [JYAutoCompleteDataSource sharedDataSource];
    _emailField.autocompleteType = JYAutoCompleteTypeEmail;
    _emailField.delegate = self;
    _emailField.floatingLabel.font = [UIFont systemFontOfSize:kSignFieldFloatingLabelFontSize];
    _emailField.font = [UIFont systemFontOfSize:kSignFieldFontSize];
    _emailField.keyboardType = UIKeyboardTypeEmailAddress;
    _emailField.returnKeyType = UIReturnKeyNext;

    [self.view addSubview:_emailField];
}

- (void)_createPartingLine
{
    _partingLine = [UIView new];
    _partingLine.frame = CGRectMake(kSignFieldMarginLeft, _emailField.frame.origin.y + _emailField.frame.size.height,
                                    self.view.frame.size.width - 2 * kSignFieldMarginLeft, 1.0f);
    _partingLine.backgroundColor = [FlatGray colorWithAlphaComponent:0.3f];
    [self.view addSubview:_partingLine];
}

- (void)_createPasswordField
{
    _passwordField =
        [[JYFloatLabeledTextField alloc] initWithFrame:CGRectMake(kSignFieldMarginLeft, _partingLine.frame.origin.y + _partingLine.frame.size.height,
                                                                  self.view.frame.size.width - 2 * kSignFieldMarginLeft, kSignFieldHeight)];

    _passwordField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Password", nil) attributes:@{NSForegroundColorAttributeName : FlatGray}];
    _passwordField.delegate = self;
    _passwordField.floatingLabel.font = [UIFont systemFontOfSize:kSignFieldFloatingLabelFontSize];
    _passwordField.font = [UIFont systemFontOfSize:kSignFieldFontSize];
    _passwordField.returnKeyType = UIReturnKeyDone;
    _passwordField.secureTextEntry = YES;

    [self.view addSubview:_passwordField];
}

- (void)_createSignButton
{
    CGRect signButtonFrame =
        CGRectMake(kSignFieldMarginLeft, self.passwordField.frame.origin.y + self.passwordField.frame.size.height + kSignButtonMarginTop,
                   self.view.frame.size.width - 2 * kSignFieldMarginLeft, kSignButtonHeight);

    _signButton = [[MRoundedButton alloc] initWithFrame:signButtonFrame buttonStyle:MRoundedButtonDefault];
    _signButton.backgroundColor = ClearColor;
    _signButton.contentAnimateToColor = FlatGreen;
    _signButton.contentColor = FlatWhite;
    _signButton.cornerRadius = kButtonCornerRadius;
    _signButton.foregroundAnimateToColor = FlatWhite;
    _signButton.foregroundColor = FlatGreen;
    _signButton.textLabel.font = [UIFont boldSystemFontOfSize:kSignFieldFontSize];

    [self.view addSubview:_signButton];
}
@end
