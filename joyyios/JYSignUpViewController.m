//
//  JYSignUpViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/28/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYButton.h"
#import "JYProfileViewController.h"
#import "JYSignUpViewController.h"

@interface JYSignUpViewController ()
@end

@implementation JYSignUpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.signButton addTarget:self action:@selector(_signUp) forControlEvents:UIControlEventTouchUpInside];

    self.title = NSLocalizedString(@"Sign up", nil);
    self.signButton.textLabel.text = NSLocalizedString(@"Sign Up", nil);
    self.headerLabel.text = NSLocalizedString(@"Username can only contain letters, numbers and underscore.", nil);

    [self.usernameField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)_usernameExist:(BOOL)exist
{
    self.usernameField.textColor = exist? JoyyRed: FlatGreen;
}

- (void)_showProfileView
{
    UIViewController *viewController = [JYProfileViewController new];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.passwordField)
    {
        return;
    }

    if (textField.text && [textField.text length] >= 4)
    {
        [self _fetchExistenceOfUsername:self.usernameField.text];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.usernameField)
    {
        NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];

        if (![newStr onlyContainsAlphanumericUnderscore])
        {
            return NO;
        }
    
        if (newStr.length >= 4)
        {
            [self _fetchExistenceOfUsername:newStr];
        }
    }
    return [super textField:textField shouldChangeCharactersInRange:range replacementString:string];
}

#pragma mark - Network

- (void)_signUp
{
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    [JYCredential current].username = username;
    [JYCredential current].password = password;

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSString *url = [NSString apiURLWithPath:@"auth/signup"];
    NSDictionary *parameters = @{ @"username":username, @"password":password };

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager POST:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"SignUp Success responseObject: %@", responseObject);

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [KVNProgress dismiss];

             [[JYCredential current] save:responseObject];
             [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidSignUp object:nil];
             [weakSelf _showProfileView];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"SignUp Error: %@", error);

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [KVNProgress dismiss];

             NSString *errorMessage = nil;
             errorMessage = [error.userInfo valueForKey:NSLocalizedDescriptionKey];

             [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                            message:errorMessage
                    backgroundColor:FlatYellow
                          textColor:FlatBlack
                               time:5];
         }];
}

- (void)_fetchExistenceOfUsername:(NSString *)username
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSString *url = [NSString apiURLWithPath:@"username/existence"];
    NSDictionary *parameters = @{ @"username":username };

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager GET:url
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"Success: username/existence responseObject: %@", responseObject);
              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

              BOOL doesExist = [[responseObject objectForKey:@"existence"] boolValue];
              [weakSelf _usernameExist:doesExist];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: username/existence error = %@", error);
              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
          }];
}

@end
