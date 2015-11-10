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
#import "JYSignUpViewController.h"

@interface JYSignUpViewController ()
@property (nonatomic) NSMutableDictionary *usedusernameCache;
@end

@implementation JYSignUpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.signButton addTarget:self action:@selector(_signUp) forControlEvents:UIControlEventTouchUpInside];

    self.title = NSLocalizedString(@"Sign up", nil);
    self.signButton.textLabel.text = NSLocalizedString(@"Sign Up", nil);
    self.headerLabel.text = NSLocalizedString(@"Username can only contain letters, numbers and underscore.", nil);

    self.usedusernameCache = [NSMutableDictionary new];
    [self.usernameField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)_username:(NSString *)username exist:(BOOL)exist
{
    if ([username length] == 0) {
        return;
    }

    // update cache
    NSString *key = [username lowercaseString];
    [self.usedusernameCache setObject:@(exist) forKey:key];

    NSString *curr = [self.usernameField.text lowercaseString];
    if ([username isEqualToString:curr])
    {
        self.usernameField.textColor = exist? JoyyRed: FlatGreen;
    }
}

- (void)_checkExistenceOfUsername:(NSString *)username
{
    if ([username length] == 0) {
        return;
    }

    NSString *key = [username lowercaseString];
    if ([self.usedusernameCache objectForKey:key])
    {
        BOOL inUse = [[self.usedusernameCache objectForKey:key] boolValue];
        self.usernameField.textColor = inUse? JoyyRed: FlatGreen;
        return;
    }

    [self _fetchExistenceOfUsername:key];
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
        [self _checkExistenceOfUsername:self.usernameField.text];
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
            [self _checkExistenceOfUsername:newStr];
        }
    }
    return [super textField:textField shouldChangeCharactersInRange:range replacementString:string];
}

#pragma mark - Network

- (void)_signUp
{
    NSString *username = [self.usernameField.text lowercaseString];
    NSString *password = self.passwordField.text;
    [JYCredential current].username = username;
    [JYCredential current].password = password;

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSString *url = [NSString apiURLWithPath:@"auth/signup"];
    NSDictionary *parameters = @{ @"username":username, @"password":password };

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [manager POST:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"SignUp Success responseObject: %@", responseObject);

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [KVNProgress dismiss];

             [[JYCredential current] save:responseObject];
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

              NSString *username = [responseObject objectForKey:@"username"];
              BOOL exist = [[responseObject objectForKey:@"exist"] boolValue];
              [weakSelf _username:username exist:exist];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: username/existence error = %@", error);
              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
          }];
}

@end
