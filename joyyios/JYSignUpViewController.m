//
//  JYSignUpViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/28/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYButton.h"
#import "JYSignUpViewController.h"

@interface JYSignUpViewController () <FBSDKLoginButtonDelegate>
@property (nonatomic) FBSDKLoginButton *fbLoginButton;
@end

const CGFloat kFBLoginButtonHeight = 44;


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

-(FBSDKLoginButton *)fbLoginButton
{
    if (!_fbLoginButton)
    {
        _fbLoginButton = [[FBSDKLoginButton alloc] init];
        _fbLoginButton.frame = CGRectMake(0, 0, SCREEN_WIDTH - kMarginLeft - kMarginRight, kCellHeight);
        _fbLoginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    }
    return _fbLoginButton;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kFBLoginButtonHeight + self.headerLabel.height;
}

#pragma mark - UITableViewDataSource

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, kFBLoginButtonHeight + self.headerLabel.height);
    UIView *header = [[UIView alloc] initWithFrame:frame];
    header.backgroundColor = ClearColor;

    [header addSubview:self.fbLoginButton];
    self.headerLabel.y = CGRectGetMaxY(self.fbLoginButton.frame);
    [header addSubview:self.headerLabel];

    return header;
}

#pragma mark - FBSDKLoginButtonDelegate

- (void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error
{

}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton
{
    
}
#pragma mark - UITextFieldDelegate methods

// Show Red/Green boarder on the usernameField
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.passwordField)
    {
        return;
    }

    if (textField.text && [textField.text length] >= 4)
    {
        [self _getExistenceOfUsername:self.usernameField.text];
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
            [self _getExistenceOfUsername:newStr];
        }
    }
    return [super textField:textField shouldChangeCharactersInRange:range replacementString:string];
}

#pragma mark - Network

- (void)_signUp
{
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    [JYCredential mine].username = username;
    [JYCredential mine].password = password;

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSString *url = [NSString apiURLWithPath:@"credential/signup"];
    NSDictionary *parameters = @{ @"username":username, @"password":password, @"phone":self.phoneNumber };

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [manager POST:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"SignUp Success responseObject: %@", responseObject);

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [KVNProgress dismiss];
             [[JYCredential mine] save:responseObject];
             [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidSignUp object:nil];
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

- (void)_getExistenceOfUsername:(NSString *)username
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSString *url = [NSString apiURLWithPath:@"credential/existence"];
    NSDictionary *parameters = @{ @"username":username };

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager GET:url
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"Success: credential/existence responseObject: %@", responseObject);
              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

              BOOL doesExist = [[responseObject objectForKey:@"existence"] boolValue];
              [weakSelf _usernameExist:doesExist];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: credential/existence error = %@", error);
              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
          }];
}

@end
