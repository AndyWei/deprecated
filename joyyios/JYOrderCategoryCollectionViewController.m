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

@property(nonatomic) CGFloat cellWidth;
@property(nonatomic) CGFloat cellHeight;
@property(nonatomic) UICollectionView *collectionView;

@end


@implementation JYOrderCategoryCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = NSLocalizedString(@"Choose a category ...", nil);

    self.cellWidth = self.view.center.x - 1;
    self.cellHeight = self.cellWidth;

    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.minimumInteritemSpacing = 1.0f;
    layout.minimumLineSpacing = 2.0f;

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
    [self.collectionView setDataSource:self];
    [self.collectionView setDelegate:self];

    [self.collectionView registerClass:[JYCollectionViewCell class] forCellWithReuseIdentifier:@"categoryCellIdentifier"];

    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self bindNavigationBarToScrollView:self.collectionView];

    [self.view addSubview:self.collectionView];
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
    cell.label.frame = CGRectMake(0, (self.cellHeight - cellFrameHeight) / 2, self.cellWidth, cellFrameHeight);
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
    return CGSizeMake(self.cellWidth, self.cellWidth);
}

@end
