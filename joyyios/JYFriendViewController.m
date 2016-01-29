//
//  JYFriendViewController.m
//  joyyios
//
//  Created by Ping Yang on 12/10/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYFriendViewController.h"
#import "JYUserCell.h"
#import "JYUserlineViewController.h"

@interface JYFriendViewController () <JYUserBaseCellDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) NSInteger networkThreadCount;
@property (nonatomic) NSMutableArray *friendArrays;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kCellIdentifier = @"friendCell";

@implementation JYFriendViewController

- (instancetype)initWithFriendList:(NSArray *)friendList
{
    if (self = [super init])
    {
        [self _storeFriendList:friendList];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Friends", nil);

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

        _tableView.sectionIndexColor = JoyyBlue;
        _tableView.sectionIndexBackgroundColor = ClearColor;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = YES;

        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 40;

        [_tableView registerClass:[JYUserCell class] forCellReuseIdentifier:kCellIdentifier];
    }
    return _tableView;
}

- (void)_storeFriendList:(NSArray *)list
{
    self.friendArrays = [NSMutableArray new];
    NSInteger count = [list count];
    if (count == 0)
    {
        return;
    }

    // Get sorted friend username list
    NSMutableArray *usernames = [[NSMutableArray alloc] initWithCapacity:count];
    NSMutableDictionary *friendDict = [[NSMutableDictionary alloc] init];

    for (JYFriend *friend in list)
    {
        if (friend)
        {
            [usernames addObject:friend.username];
            [friendDict setObject:friend forKey:friend.username];
        }
    }

    [usernames sortUsingSelector:@selector(localizedCompare:)];

    // Construct friendArrays
    // self.friendArrays is a list of lists. Use friendArrays[section][row] to get an user
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];

    NSInteger n = [[collation sectionTitles] count];
    for (int i = 0; i < n; i++)
    {
        NSMutableArray *friendList = [NSMutableArray arrayWithCapacity:1];
        [self.friendArrays addObject:friendList];
    }

    // Fill in users
    for (NSString *username in usernames)
    {
        NSInteger section = [collation sectionForObject:username collationStringSelector:@selector(self)];
        NSMutableArray *friendList = [self.friendArrays objectAtIndex:section];
        JYFriend *friend = friendDict[username];
        [friendList addObject:friend];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.friendArrays count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray *array = [self.friendArrays objectAtIndex:section];
    return [array count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *array = [self.friendArrays objectAtIndex:section];

    if ([array count] > 0)
    {
        return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section];
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYUserCell *cell =
    (JYUserCell *)[tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];

    NSArray *array = [self.friendArrays objectAtIndex:indexPath.section];
    cell.user = array[indexPath.row];
    cell.delegate = self;

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSArray *array = [self.friendArrays objectAtIndex:indexPath.section];
    JYFriend *friend = array[indexPath.row];

    JYUserlineViewController *viewController = [[JYUserlineViewController alloc] initWithUser:friend];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - JYUserBaseCellDelegate

- (void)didTapActionButtonOnCell:(JYUserBaseCell *)cell
{
    if (!cell || !cell.user)
    {
        return;
    }

    JYFriend *friend = (JYFriend *)cell.user;
    [self _chatWith:friend];
}

- (void)_chatWith:(JYFriend *)friend
{
    NSDictionary *info = @{@"friend": friend};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWillChat object:nil userInfo:info];
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
}

@end
