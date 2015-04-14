//
//  JYNearbyViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYNearbyViewController.h"
#import "JYOrderViewCell.h"

@interface JYNearbyViewController ()

@property (nonatomic) NSArray *ordersList;
@property (nonatomic) UITableView *tableView;

@end

@implementation JYNearbyViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Orders Nearby", nil);
    self.navigationController.navigationBar.translucent = YES;

    [self _createTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_createTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.backgroundColor = FlatWhite;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[JYOrderViewCell class] forCellReuseIdentifier:@"orderCellIdentifier"];
    [self.view addSubview:self.tableView];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.ordersList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYOrderViewCell *cell =
    (JYOrderViewCell *)[tableView dequeueReusableCellWithIdentifier:@"orderCellIdentifier" forIndexPath:indexPath];

//    MKMapItem *item = (MKMapItem *)[self.placesList objectAtIndex:indexPath.row];

//    cell.topLabel.text = item.name;
//    cell.bottomLabel.text = (item.placemark)? item.placemark.title: NSLocalizedString(@"Current Place", nil);
//    cell.iconView.image = [UIImage imageNamed:[self _imageNameForMapItem:item]];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    MKMapItem *item = (MKMapItem *)[self.placesList objectAtIndex:indexPath.row];
//    [self.delegate placesViewController:self placemarkSelected:item.placemark];
//    [self _close];
}

@end
