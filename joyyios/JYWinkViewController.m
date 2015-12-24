//
//  JYWinkViewController.m
//  joyyios
//
//  Created by Ping Yang on 12/23/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "JYCredential.h"
#import "JYFriendManager.h"
#import "JYLocalDataManager.h"
#import "JYUserCell.h"
#import "JYUserlineViewController.h"
#import "JYWinkViewController.h"

@interface JYWinkViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) NSMutableArray *winkList;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kCellIdentifier = @"winkCell";

@implementation JYWinkViewController

- (instancetype)initWithWinkList:(NSMutableArray *)winkList
{
    if (self = [super init])
    {
        self.winkList = winkList;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Winks", nil);

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
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = YES;

        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 40;

        [_tableView registerClass:[JYUserCell class] forCellReuseIdentifier:kCellIdentifier];
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.winkList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYUserCell *cell =
    (JYUserCell *)[tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];

    JYUser *user = [self.winkList objectAtIndex:indexPath.row];
    cell.user = user;

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    JYUser *user = [self.winkList objectAtIndex:indexPath.row];

    JYUserlineViewController *viewController = [[JYUserlineViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Network


@end
