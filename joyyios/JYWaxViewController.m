//
//  JYWaxViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/7/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYWaxViewController.h"

@interface JYWaxViewController ()
{
    BOOL _isDragging;
    CGFloat _tabBarOriginalY;
    CGFloat _lastOffsetY;
}
@end

@implementation JYWaxViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tabBarOriginalY = CGRectGetMinY(self.tabBarController.tabBar.frame);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _isDragging = YES;
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
    CGRect frame = self.tabBarController.tabBar.frame;

    if (!_isDragging)
    {
        _lastOffsetY = offsetY;
        return;
    }

    // reached the bottom
    if ([self _reachedBottomOfView:scrollView])
    {
        _lastOffsetY = offsetY;
        [self _show:YES];
    }
    else
    {
        CGFloat delta = offsetY - _lastOffsetY;
        _lastOffsetY = offsetY;

        frame.origin.y += delta;
        frame.origin.y = fmin(CGRectGetMaxY(self.view.frame), frame.origin.y);
        frame.origin.y = fmax(_tabBarOriginalY, frame.origin.y);
        self.tabBarController.tabBar.frame = frame;
    }
}

#pragma mark - Helpers

- (BOOL)_reachedBottomOfView:(UIScrollView *)scrollView
{
    return (scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height);
}

- (void)_stoppedScrollingView:(UIScrollView *)scrollView
{
    _isDragging = NO;

    if ([self _reachedBottomOfView:scrollView])
    {
        [self _show:YES];
    }
    else
    {
        CGFloat currentY = self.tabBarController.tabBar.frame.origin.y;
        CGFloat midY = (CGRectGetMaxY(self.view.frame) + _tabBarOriginalY) / 2;
        [self _show:(currentY < midY)];
    }
}

- (void)_show:(BOOL)show
{
    CGRect tabBarFrame = self.tabBarController.tabBar.frame;
    tabBarFrame.origin.y = show ? _tabBarOriginalY: CGRectGetMaxY(self.view.frame);
    [self _showTabBarWithFrame:tabBarFrame];
}

- (void)_showTabBarWithFrame:(CGRect)frame
{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2
                     animations:^{
                         weakSelf.tabBarController.tabBar.frame = frame;
                     }];
}

@end
