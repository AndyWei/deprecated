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
    [JYCredential current].username = self.username;
    [JYCredential current].password = self.passwordField.text;

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager managerWithPassword];
    NSString *url = [NSString apiURLWithPath:@"auth/signin"];

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [manager GET:url
        parameters:nil
        success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"SignIn Success responseObject: %@", responseObject);

            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [KVNProgress dismiss];
            [[JYCredential current] save:responseObject];

            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidSignIn object:nil];
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
