//
//  JYSessionListViewController.m
//  joyyios
//
//  Created by Ping Yang on 8/27/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYFriendManager.h"
#import "JYFriendViewController.h"
#import "JYSessionListViewCell.h"
#import "JYSessionListViewController.h"
#import "JYSessionViewController.h"
#import "JYXmppManager.h"

@interface JYSessionListViewController () <NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) NSFetchedResultsController *fetcher;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kContactCellIdentifier = @"contactCell";

@implementation JYSessionListViewController

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

    // Start fetch data
    self.fetcher = [JYXmppManager fetcherOfSessions];
    self.fetcher.delegate = self;
    NSError *error = nil;
    [self.fetcher performFetch:&error];
    if (error)
    {
        NSLog(@"fetcher performFetch error = %@", error);
    }

    [self.view addSubview:self.tableView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_willChatWithFriend:) name:kNotificationWillChat object:nil];
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
        _tableView.backgroundColor = JoyyBlack;
        _tableView.showsHorizontalScrollIndicator = NO;
        [_tableView registerClass:[JYSessionListViewCell class] forCellReuseIdentifier:kContactCellIdentifier];
    }
    return _tableView;
}

- (void)_willChatWithFriend:(NSNotification *)notification
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
    [self _chatWithFriend:friend];
}

- (void)_showFriendList
{
    NSArray *friendList = [JYFriendManager sharedInstance].localFriendList;
    JYFriendViewController *viewController = [[JYFriendViewController alloc] initWithFriendList:friendList];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)_chatWithFriend:(JYFriend *)friend
{
    JYSessionViewController *viewController = [JYSessionViewController new];
    viewController.friend = friend;
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger number = self.fetcher.sections.count;
    return number;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger number = [[self.fetcher.sections objectAtIndex:section] numberOfObjects];
    return number;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYSessionListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kContactCellIdentifier forIndexPath:indexPath];

    cell.contact = [self.fetcher objectAtIndexPath:indexPath];

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
        [self _chatWithFriend:cell.friend];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

// When a message received , XMPPFramework will archive the message to CoreData storage, and update contacts.
// Thus the controllerDidChangeContent will be triggered
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}

@end
