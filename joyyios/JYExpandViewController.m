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
@property(nonatomic) UILabel *titleLabel;

@end

@implementation JYExpandViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:5.0f forBarMetrics:UIBarMetricsDefault];

    self.tabBarOriginalY = CGRectGetMinY(self.tabBarController.tabBar.frame);
    self.navBarOriginalHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
    self.navBarMinHeight = self.navBarOriginalHeight * 0.5;

    self.titleLabel = [[UILabel alloc] initWithFrame:self.navigationController.navigationBar.frame];
    self.titleLabel.backgroundColor = ClearColor;
    self.titleLabel.font = [UIFont systemFontOfSize:kNavBarTitleFontSize];
    self.titleLabel.textColor = FlatBlack;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = self.titleLabel;

    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_scrollToTop)];
    self.navigationItem.titleView.userInteractionEnabled = YES;
    [self.navigationItem.titleView addGestureRecognizer:tapGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTitleText:(NSString *)text
{
    self.titleLabel.text = text;
    [self.titleLabel sizeToFit];
}

- (void)resetNavigationBar:(BOOL)animated
{
    if (!animated)
    {
        self.navigationController.navigationBar.height = self.navBarOriginalHeight;
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.15 animations:^{
            [weakSelf resetNavigationBar:NO];
        }];
    }
}

- (void)_scrollToTop
{
    if (self.scrollView)
    {
        [self resetNavigationBar:YES];
        [self.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    }
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
