//
//  JYWaxViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/7/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYExpandViewController.h"

@interface JYExpandViewController ()

@property(nonatomic) BOOL isDragging;
@property(nonatomic) CGFloat lastOffsetY;
@property(nonatomic) CGFloat navBarOriginalHeight;
@property(nonatomic) CGFloat navBarMinHeight;
@property(nonatomic) CGFloat tabBarOriginalY;

@end

@implementation JYExpandViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tabBarOriginalY = CGRectGetMinY(self.tabBarController.tabBar.frame);
    self.navBarOriginalHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
    self.navBarMinHeight = self.navBarOriginalHeight * 0.37;

    self.navigationBarLabel = [[UILabel alloc] initWithFrame:self.navigationController.navigationBar.frame];
    self.navigationBarLabel.backgroundColor = ClearColor;
    self.navigationBarLabel.font = [UIFont lightSystemFontOfSize:kNavBarTitleFontSize];
    self.navigationBarLabel.textColor = FlatBlack;
    self.navigationBarLabel.textAlignment = NSTextAlignmentCenter;

    self.navigationItem.titleView = self.navigationBarLabel;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.isDragging = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self _stoppedScrollingView:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self _stoppedScrollingView:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offsetY = scrollView.contentOffset.y;

    if (!self.isDragging)
    {
        self.lastOffsetY = offsetY;
        return;
    }

    // reached the bottom
    if ([self _reachedBottomOfView:scrollView])
    {
        self.lastOffsetY = offsetY;
        [self _showTabBar:YES];
    }
    else
    {
        CGFloat delta = (offsetY - self.lastOffsetY) * 0.5;
        self.lastOffsetY = offsetY;

        if (delta == 0.0f)
        {
            return;
        }

        // Continiously change tab bar's y, but keep it in the range of [self.tabBarOriginalY, CGRectGetMaxY(self.view.frame)]
        CGRect tabBarFrame = self.tabBarController.tabBar.frame;
        tabBarFrame.origin.y += delta;
        tabBarFrame.origin.y = fmin(CGRectGetMaxY(self.view.frame), tabBarFrame.origin.y);
        tabBarFrame.origin.y = fmax(self.tabBarOriginalY, tabBarFrame.origin.y);
        self.tabBarController.tabBar.frame = tabBarFrame;

        // Continiously change nav bar's height, but keep it in the range of [self.navBarMinHeight, self.navBarOriginalHeight]
        CGRect navBarFrame = self.navigationController.navigationBar.frame;
        navBarFrame.size.height -= delta;
        navBarFrame.size.height = fmax(self.navBarMinHeight, fmin(self.navBarOriginalHeight, navBarFrame.size.height));
        self.navigationController.navigationBar.frame = navBarFrame;

        // Continiously change nav bar label view's font size
        CGFloat shrinkFactor = navBarFrame.size.height / self.navBarOriginalHeight;
        CGFloat fontSize = fmax(13.0f, kNavBarTitleFontSize * shrinkFactor);
        self.navigationBarLabel.font = [UIFont lightSystemFontOfSize:fontSize];
    }
}

#pragma mark - Helpers

- (BOOL)_reachedBottomOfView:(UIScrollView *)scrollView
{
    return (scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height);
}

- (void)_stoppedScrollingView:(UIScrollView *)scrollView
{
    self.isDragging = NO;
    self.lastOffsetY = scrollView.contentOffset.y;

    if ([self _reachedBottomOfView:scrollView])
    {
        [self _showTabBar:YES];
    }
    else
    {
        CGFloat currentY = self.tabBarController.tabBar.frame.origin.y;
        CGFloat midY = (CGRectGetMaxY(self.view.frame) + self.tabBarOriginalY) / 2;
        [self _showTabBar:(currentY < midY)];
    }
}

- (void)_showTabBar:(BOOL)show
{
    CGRect tabBarFrame = self.tabBarController.tabBar.frame;
    tabBarFrame.origin.y = show ? self.tabBarOriginalY: CGRectGetMaxY(self.view.frame);

    [self _showTabBarWithFrame:tabBarFrame];
}

- (void)_showTabBarWithFrame:(CGRect)tabBarFrame
{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.1
                     animations:^{
                         weakSelf.tabBarController.tabBar.frame = tabBarFrame;
                     }];
}

@end
