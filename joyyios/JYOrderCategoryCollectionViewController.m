//
//  JYOrderCategoryCollectionViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYCollectionViewCell.h"
#import "JYOrderCategoryCollectionViewController.h"
#import "JYOrderCreateLocationViewController.h"
#import "JYServiceCategory.h"

@interface JYOrderCategoryCollectionViewController ()
{
    BOOL _isDragging;
    CGFloat _cellWidth;
    CGFloat _cellHeight;
    CGFloat _tabBarOriginalY;
    CGFloat _lastOffsetY;
    UICollectionView *_collectionView;
}
@end


@implementation JYOrderCategoryCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = NSLocalizedString(@"Choose a category ...", nil);

    _cellWidth = self.view.center.x - 1;
    _cellHeight = _cellWidth;
    _tabBarOriginalY = CGRectGetMinY(self.tabBarController.tabBar.frame);

    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.minimumInteritemSpacing = 1.0f;
    layout.minimumLineSpacing = 2.0f;

    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
    [_collectionView setDataSource:self];
    [_collectionView setDelegate:self];

    [_collectionView registerClass:[JYCollectionViewCell class] forCellWithReuseIdentifier:@"categoryCellIdentifier"];

    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self bindNavigationBarToScrollView:_collectionView];

    [self.view addSubview:_collectionView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [JYServiceCategory names].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JYCollectionViewCell *cell =
        (JYCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"categoryCellIdentifier" forIndexPath:indexPath];

    CGFloat cellFrameHeight = 40.0f;
    cell.label.frame = CGRectMake(0, (_cellHeight - cellFrameHeight) / 2, _cellWidth, cellFrameHeight);
    cell.label.text = [JYServiceCategory names][indexPath.item];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    JYOrderCreateLocationViewController *viewController = [JYOrderCreateLocationViewController new];
    viewController.serviceCategoryIndex = indexPath.item;
    [self.navigationController pushViewController:viewController animated:YES];
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                    layout:(UICollectionViewLayout *)collectionViewLayout
    sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(_cellWidth, _cellWidth);
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
    if ([self reachedBottomOfView:scrollView])
    {
        _lastOffsetY = offsetY;
        frame.origin.y = _tabBarOriginalY;

        [self _showTabBarWithFrame:frame];
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

# pragma mark - Helpers

- (void) _stoppedScrollingView:(UIScrollView *)scrollView
{
    _isDragging = NO;

    CGRect frame = self.tabBarController.tabBar.frame;
    if ([self reachedBottomOfView:scrollView])
    {
        frame.origin.y = _tabBarOriginalY;
    }
    else
    {
        CGFloat y = frame.origin.y;
        CGFloat midY = (CGRectGetMaxY(self.view.frame) + _tabBarOriginalY) / 2;
        frame.origin.y = (y < midY)? _tabBarOriginalY: CGRectGetMaxY(self.view.frame);
    }
    [self _showTabBarWithFrame:frame];
}


- (void)_showTabBarWithFrame:(CGRect)frame
{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2 animations:^{
        weakSelf.tabBarController.tabBar.frame = frame;
    }];
}

- (BOOL)reachedBottomOfView:(UIScrollView *)scrollView
{
    return (scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height);
}

@end
