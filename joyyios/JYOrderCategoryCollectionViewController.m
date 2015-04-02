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
    CGFloat _cellWidth;
    CGFloat _cellHeight;
    UICollectionView *_collectionView;
}
@end

@implementation JYOrderCategoryCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Choose a category ...", nil);

    _cellWidth = self.view.center.x - 1;
    _cellHeight = _cellWidth;

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

@end
