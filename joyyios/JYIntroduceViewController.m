//
//  JYIntroViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYIntroduceViewController.h"

static NSString *const sampleDescription1 =
    @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
static NSString *const sampleDescription2 = @"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, "
    @"totam rem aperiam, eaque ipsa quae ab illo inventore.";
static NSString *const sampleDescription3 = @"Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia "
    @"non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.";
static NSString *const sampleDescription4 = @"Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit.";

@interface JYIntroduceViewController ()
{
    UIView *rootView;
}
@end

@implementation JYIntroduceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Set the navigationBar to be transparent, which will prevent ugly empty view after the introview dismissed
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;

    rootView = self.navigationController.view;
    rootView.backgroundColor = FlatSkyBlue;
    [self _introduce];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_introduce
{
    EAIntroPage *page1 = [EAIntroPage page];
    page1.title = @"Hello world";
    page1.desc = sampleDescription1;
    //    page1.bgImage = [UIImage imageNamed:@"bg1"];
    //    page1.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title1"]];

    EAIntroPage *page2 = [EAIntroPage page];
    page2.title = @"This is page 2";
    page2.desc = sampleDescription2;
    //    page2.bgImage = [UIImage imageNamed:@"bg2"];
    //    page2.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title2"]];

    EAIntroPage *page3 = [EAIntroPage page];
    page3.title = @"This is page 3";
    page3.desc = sampleDescription3;
    //    page3.bgImage = [UIImage imageNamed:@"bg3"];
    //    page3.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title3"]];

    EAIntroPage *page4 = [EAIntroPage page];
    page4.title = @"This is page 4";
    page4.desc = sampleDescription4;
    //    page4.bgImage = [UIImage imageNamed:@"bg4"];
    //    page4.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title4"]];

    EAIntroView *introduceView = [[EAIntroView alloc] initWithFrame:rootView.bounds andPages:@[ page1, page2, page3, page4 ]];
    [introduceView setDelegate:self];
    introduceView.backgroundColor = FlatSkyBlue;

    [introduceView showInView:rootView animateDuration:0.3];
}

#pragma mark - EAIntroView delegate

- (void)introDidFinish:(EAIntroView *)introView
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationIntroduceDidFinish object:nil];
}

@end
