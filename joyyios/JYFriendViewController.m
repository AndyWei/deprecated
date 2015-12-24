//
//  JYFriendViewController.m
//  joyyios
//
//  Created by Ping Yang on 12/10/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "JYCredential.h"
#import "JYFriendManager.h"
#import "JYFriendViewController.h"
#import "JYLocalDataManager.h"
#import "JYUserCell.h"
#import "JYUserlineViewController.h"

@interface JYFriendViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) NSInteger networkThreadCount;
@property (nonatomic) NSMutableArray *friendArrays;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kCellIdentifier = @"friendCell";

@implementation JYFriendViewController

- (instancetype)init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_apiTokenReady) name:kNotificationAPITokenReady object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Friends", nil);

    self.navigationController.navigationBar.translucent = YES;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];

    self.networkThreadCount = 0;

    if (!self.friendArrays && [JYCredential current].tokenValidInSeconds > 0)
    {
        self.friendArrays = [NSMutableArray new];
        [self _fetchFriends];
    }
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
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = YES;

        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 40;

        [_tableView registerClass:[JYUserCell class] forCellReuseIdentifier:kCellIdentifier];
    }
    return _tableView;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_apiTokenReady
{
    [self _fetchFriends];
}

- (void)_networkThreadBegin
{
    if (self.networkThreadCount == 0)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    self.networkThreadCount++;
}

- (void)_networkThreadEnd
{
    self.networkThreadCount--;
    if (self.networkThreadCount <= 0)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

- (void)_receivedFriendList:(NSArray *)friendList
{
    NSInteger count = [friendList count];
    if (count == 0)
    {
        return;
    }

    // Get sorted friend username list
    NSMutableArray *usernames = [[NSMutableArray alloc] initWithCapacity:count];
    NSMutableDictionary *friendDict = [[NSMutableDictionary alloc] init];

    for (JYFriend *user in friendList)
    {
        if (user)
        {
            [usernames addObject:user.username];
            [friendDict setObject:user forKey:user.username];
        }
    }

    [usernames sortUsingSelector:@selector(localizedCompare:)];

    // Construct friendArrays
    // self.friendArrays is a list of lists. Use friendArrays[section][row] to get an user
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];

    NSInteger n = [[collation sectionTitles] count];
    self.friendArrays = [NSMutableArray arrayWithCapacity:n];
    for (int i = 0; i < n; i++)
    {
        NSMutableArray *friendList = [NSMutableArray arrayWithCapacity:1];
        [self.friendArrays addObject:friendList];
    }

    // Fill in countries
    for (NSString *username in usernames)
    {
        NSInteger section = [collation sectionForObject:username collationStringSelector:@selector(self)];
        NSMutableArray *friendList = [self.friendArrays objectAtIndex:section];
        JYFriend *user = friendDict[username];
        [friendList addObject:user];
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

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSArray *array = [self.friendArrays objectAtIndex:indexPath.section];
    JYFriend *user = array[indexPath.row];

    JYUserlineViewController *viewController = [[JYUserlineViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Network

- (void)_fetchFriends
{
    NSString *url = [NSString apiURLWithPath:@"friends"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:nil
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"GET friends Success");

             NSMutableArray *friendList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 NSError *error = nil;
                 JYFriend *friend = (JYFriend *)[MTLJSONAdapter modelOfClass:JYFriend.class fromJSONDictionary:dict error:&error];
                 if (friend)
                 {
                     [friendList addObject:friend];
                 }
             }

             [weakSelf _receivedFriendList:friendList];
             if (weakSelf.isViewLoaded)
             {
                 [weakSelf.tableView reloadData];
             }
             [[JYFriendManager sharedInstance] receivedFriendList:friendList];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"GET friends error: %@", error);
         }];
}

@end
