//
//  JYModalViewController.m
//  joyyios
//
//  Created by Ping Yang on 7/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYModalViewController.h"

@interface JYModalViewController ()

@end

@implementation JYModalViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"DONE" style:UIBarButtonItemStylePlain target:self action:@selector(_done)];
    self.navigationItem.leftBarButtonItem = doneButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)_done
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
