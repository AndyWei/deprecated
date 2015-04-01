//
//  JYHomeViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYCollectionViewCell.h"
#import "JYHomeViewController.h"

@interface JYHomeViewController ()
{
    CGFloat _cellWidth;
    CGFloat _cellHeight;
    UICollectionView *_collectionView;
    NSArray *_serviceCategories;
}
@end

@implementation JYHomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _cellWidth = self.view.center.x - 1;
    _cellHeight = _cellWidth;

    _serviceCategories = @[
        NSLocalizedString(@"Roadside Aid", nil),
        NSLocalizedString(@"Ride", nil),
        NSLocalizedString(@"Moving", nil),
        NSLocalizedString(@"Delivery", nil),
        NSLocalizedString(@"Plumbing", nil),
        NSLocalizedString(@"Cleaning", nil),
        NSLocalizedString(@"Handyman", nil),
        NSLocalizedString(@"Gardener", nil),
        NSLocalizedString(@"Personal Assistant", nil),
        NSLocalizedString(@"Other", nil)
    ];

    self.navigationItem.title = NSLocalizedString(@"Choose a category ...", nil);

    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.minimumInteritemSpacing = 1.0f;
    layout.minimumLineSpacing = 2.0f;

    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
    [_collectionView setDataSource:self];
    [_collectionView setDelegate:self];

    [_collectionView registerClass:[JYCollectionViewCell class] forCellWithReuseIdentifier:@"homeCellIdentifier"];

    _collectionView.backgroundColor = FlatWhite;
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
    return _serviceCategories.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JYCollectionViewCell *cell =
        (JYCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"homeCellIdentifier" forIndexPath:indexPath];

    CGFloat cellFrameHeight = 40.0f;
    cell.label.frame = CGRectMake(0, (_cellHeight - cellFrameHeight) / 2, _cellWidth, cellFrameHeight);
    cell.label.text = _serviceCategories[indexPath.item];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];

    JYHomeViewController *viewController = [JYHomeViewController new];
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
