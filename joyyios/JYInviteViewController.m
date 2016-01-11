//
//  JYInviteViewController.m
//  joyyios
//
//  Created by Ping Yang on 1/11/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "JYCredential.h"
#import "JYFriendManager.h"
#import "JYInviteViewController.h"
#import "JYLocalDataManager.h"
#import "JYUserlineViewController.h"
#import "JYContactCell.h"


@interface JYInviteViewController () <JYUserBaseCellDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) NSMutableArray *inviteList;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kCellIdentifier = @"inviteCell";

@implementation JYInviteViewController

- (instancetype)initWithInviteList:(NSMutableArray *)inviteList
{
    if (self = [super init])
    {
        self.inviteList = inviteList;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Invites", nil);

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
    return [self.inviteList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYContactCell *cell =
    (JYContactCell *)[tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];

    JYUser *user = [self.inviteList objectAtIndex:indexPath.row];
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

    JYUser *user = [self.inviteList objectAtIndex:indexPath.row];
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

    [self _acceptInviteFromUser:cell.user];
}

#pragma mark - Network

- (void)_acceptInviteFromUser:(JYUser *)user
{
    
}

@end
