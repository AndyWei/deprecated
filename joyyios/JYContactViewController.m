//
//  JYContactViewController.m
//  joyyios
//
//  Created by Ping Yang on 1/5/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "JYContactCell.h"
#import "JYContactViewController.h"
#import "JYCredential.h"
#import "JYFriendManager.h"
#import "JYLocalDataManager.h"
#import "JYUserlineViewController.h"


@interface JYContactViewController () <JYUserBaseCellDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) NSMutableArray *contactList;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kCellIdentifier = @"contactCell";

@implementation JYContactViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Contacts", nil);

    self.navigationController.navigationBar.translucent = YES;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];

    [self.view addSubview:self.tableView];
}

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;

        _tableView.sectionIndexBackgroundColor = ClearColor;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = YES;

        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 60;

        [_tableView registerClass:[JYContactCell class] forCellReuseIdentifier:kCellIdentifier];
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.contactList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYContactCell *cell =
    (JYContactCell *)[tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];

    JYUser *user = [self.contactList objectAtIndex:indexPath.row];
    cell.user = user;
    cell.delegate = self;

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    JYUser *user = [self.contactList objectAtIndex:indexPath.row];
    JYUserlineViewController *viewController = [[JYUserlineViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - JYUserBaseCellDelegate

- (void)didTapActionButtonOnCell:(JYUserBaseCell *)cell
{
    if (!cell || !cell.user)
    {
        return;
    }

    [self _connectUser:cell.user];
}

#pragma mark - Network

- (void)_connectUser:(JYUser *)user
{

}


@end
