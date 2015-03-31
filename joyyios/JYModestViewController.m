//
//  JYModestViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/31/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYModestViewController.h"

@interface JYModestViewController ()

@end

@implementation JYModestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([self.navigationController respondsToSelector:@selector(hidesBarsOnSwipe)])
    {
        self.navigationController.hidesBarsOnSwipe = YES;
    }

//    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 1000);
    self.originalFrame = self.tabBarController.tabBar.frame;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{

    UITabBar *tabBar = self.tabBarController.tabBar;

    NSInteger yOffset = scrollView.contentOffset.y;
    CGFloat yPanGesture = [scrollView.panGestureRecognizer translationInView:self.view].y;
    CGFloat heightTabBar = tabBar.frame.size.height;

    CGFloat tabBarOriginY = tabBar.frame.origin.y;
    CGFloat frameHeight = self.view.frame.size.height;

    if (yOffset >= heightTabBar)
        yOffset = heightTabBar;

    // GOING UP ------------------
    if (yPanGesture >= 0 && yPanGesture < heightTabBar && tabBarOriginY > frameHeight - heightTabBar)
    {
        yOffset = heightTabBar - fabsf(yPanGesture);
    }
    else if (yPanGesture >= 0 && yPanGesture < heightTabBar && tabBarOriginY <= frameHeight - heightTabBar)
    {
        yOffset = 0;
    }
    // GOING DOWN ------------------
    else if (yPanGesture < 0 && tabBarOriginY < frameHeight)
    {
        yOffset = fabsf(yPanGesture);
    }
    else if (yPanGesture < 0 && tabBarOriginY >= frameHeight)
    {
        yOffset = heightTabBar;
    }
    else
    {
        yOffset = 0;
    }

    if (yOffset > 0)
    {
        tabBar.frame = CGRectMake(tabBar.frame.origin.x, self.originalFrame.origin.y + yOffset, tabBar.frame.size.width, tabBar.frame.size.height);
    }
    else if (yOffset <= 0)
    {
        tabBar.frame = self.originalFrame;
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{

    // Handle unfinished animations
    UITabBar *tabBar = self.tabBarController.tabBar;
    CGFloat yPanGesture = [scrollView.panGestureRecognizer translationInView:self.view].y;
    CGFloat heightTabBar = tabBar.frame.size.height;
    CGFloat tabBarOriginY = tabBar.frame.origin.y;
    CGFloat frameHeight = self.view.frame.size.height;

    if (yPanGesture > 0)
    {

        if (tabBarOriginY != frameHeight - heightTabBar)
        {

            [UIView animateWithDuration:0.3
                             animations:^(void) {
                               tabBar.frame = self.originalFrame;
                             }];
        }
    }
    else if (yPanGesture < 0)
    {

        if (tabBarOriginY != frameHeight)
        {
            [UIView animateWithDuration:0.3
                             animations:^(void) {
                               tabBar.frame = CGRectMake(tabBar.frame.origin.x, frameHeight, tabBar.frame.size.width, tabBar.frame.size.height);
                             }];
        }
    }
}

@end
