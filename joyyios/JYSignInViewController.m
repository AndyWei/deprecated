//
//  JYSignInViewController.m
//  joyy
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYButton.h"
#import "JYSignInViewController.h"

@interface JYSignInViewController ()
@end

@implementation JYSignInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Welcome Back!", nil);

    self.signButton.textLabel.text = NSLocalizedString(@"Sign In", nil);
    [self.signButton addTarget:self action:@selector(_signIn) forControlEvents:UIControlEventTouchUpInside];

    self.usernameField.text = self.username;
    self.usernameField.userInteractionEnabled = NO;

    [self.passwordField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)_signIn
{
    NSString *username = [self.usernameField.text lowercaseString];
    NSString *password = self.passwordField.text;
    [JYCredential current].username = username;
    [JYCredential current].password = password;

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *url = [NSString apiURLWithPath:@"auth/signin"];

    NSDictionary *parameters = @{ @"username":username, @"password":password };
    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [manager POST:url
        parameters:parameters
        success:^(NSURLSessionTask *operation, id responseObject) {
            NSLog(@"SignIn Success responseObject: %@", responseObject);

            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [KVNProgress dismiss];

            [[JYCredential current] save:responseObject];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidSignIn object:nil];
        }
        failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"SignIn Error: %@", error);

            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [KVNProgress dismiss];

            NSString *errorMessage = nil;
            if (error.code == NSURLErrorBadServerResponse)
            {
                errorMessage = NSLocalizedString(kErrorSignInFailed, nil);
            }
            else
            {
                errorMessage = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
            }

            [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                           message:errorMessage
                   backgroundColor:FlatYellow
                         textColor:FlatBlack
                              time:5];
        }];
}

@end
