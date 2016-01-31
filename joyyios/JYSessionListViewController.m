//
//  JYSessionListViewController.m
//  joyyios
//
//  Created by Ping Yang on 8/27/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFriendManager.h"
#import "JYFriendViewController.h"
#import "JYLocalDataManager.h"
#import "JYMessage.h"
#import "JYSession.h"
#import "JYSessionListViewCell.h"
#import "JYSessionListViewController.h"
#import "JYSessionViewController.h"
#import "JYXmppManager.h"


@interface JYSessionListViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) NSMutableArray *sessionList;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kCellIdentifier = @"sessionCell";

@implementation JYSessionListViewController

- (instancetype)init
{
    if (self = [super init])
    {
        // listen to notification now to avoid any missing 
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_chattingWithFriend:) name:kNotificationChatting object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Chat", nil);

    self.view.backgroundColor = JoyyWhitePure;
    self.tableView.backgroundColor = JoyyWhitePure;

    UIBarButtonItem *createButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(_showFriendList)];
    self.navigationItem.rightBarButtonItem = createButton;

    // Connect to Message server
    [[JYXmppManager sharedInstance] start];

    // Hide the "Back" text on the pushed view navigation bar
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];

    // Init as empty list
    self.sessionList = [NSMutableArray new];

    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // refresh data source and table
    self.sessionList = [[JYLocalDataManager sharedInstance] selectObjectsOfClass:JYSession.class withProperty:@"userid" equals:[JYCredential current].userId orderBy:@"timestamp DESC"];
    [self.tableView reloadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = JoyyWhitePure;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsHorizontalScrollIndicator = NO;
        [_tableView registerClass:[JYSessionListViewCell class] forCellReuseIdentifier:kCellIdentifier];
    }
    return _tableView;
}

- (void)_chattingWithFriend:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (!info)
    {
        return;
    }

    id obj = [info objectForKey:@"friend"];
    if (obj == [NSNull null])
    {
        return;
    }
    
    JYFriend *friend = (JYFriend *)obj;
    [self _showChatViewWithFriend:friend];
}

- (void)_showFriendList
{
    NSArray *friendList = [JYFriendManager sharedInstance].localFriendList;
    JYFriendViewController *viewController = [[JYFriendViewController alloc] initWithFriendList:friendList];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)_showChatViewWithFriend:(JYFriend *)friend
{
    JYSessionViewController *viewController = [JYSessionViewController new];
    viewController.friend = friend;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)_deleteSessionAtIndexPath:(NSIndexPath *)indexPath
{
    JYSession *session = self.sessionList[indexPath.row];

    // delete session
    [[JYLocalDataManager sharedInstance] deleteObject:session ofClass:JYSession.class];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.sessionList removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    });

    // delete all the messages in the session
    NSString *userId = [[JYCredential current].userId uint64String];
    NSString *peerId = [session.peerId uint64String];
    NSString *condition = [NSString stringWithFormat:@"userid = %@ AND peerid = %@", userId, peerId];
    [[JYLocalDataManager sharedInstance] deleteObjectsOfClass:JYMessage.class withCondition:condition];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger number = [self.sessionList count];
    return number;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYSessionListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    cell.session = self.sessionList[indexPath.row];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    JYSessionListViewCell *cell = (JYSessionListViewCell *)[tableView cellForRowAtIndexPath:indexPath];

    if (cell.friend)
    {
        [self _showChatViewWithFriend:cell.friend];
    }
}

// swipe-to-delete feature
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *deleteText = NSLocalizedString(@"Delete", nil);

    __weak typeof(self) weakSelf = self;
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:deleteText  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        [weakSelf _deleteSessionAtIndexPath:indexPath];
    }];

    deleteAction.backgroundColor = JoyyRed;
    return @[deleteAction];
}

@end
