//
//  JYSessionListViewController.m
//  joyyios
//
//  Created by Ping Yang on 8/27/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <SDWebImage/SDWebImageManager.h>

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
@property (nonatomic) NSMutableArray *messageList;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kCellIdentifier = @"sessionCell";

@implementation JYSessionListViewController

- (instancetype)init
{
    if (self = [super init])
    {
        self.messageList = [NSMutableArray new];

        // listen to notification in init other than viewDidload is to avoid any missing
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_chattingWithFriend:) name:kNotificationChatting object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateSession:) name:kNotificationNeedUpdateSession object:nil];
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

    // Hide the "Back" text on the pushed view navigation bar
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];

    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self _reloadMessageList];
    [self.tableView reloadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_reloadMessageList
{
    NSNumber *userId = [JYCredential current].userId;

    if (!userId || [userId unsignedLongLongValue] == 0)
    {
        return;
    }

    self.messageList = [NSMutableArray new];

    NSArray *sessions = [[JYLocalDataManager sharedInstance] selectObjectsOfClass:JYSession.class withProperty:@"user_id" equals:userId];
    NSString *userIdStr = [userId uint64String];
    for (JYSession *session in sessions)
    {
        NSString *peerIdStr = [session.sessionId uint64String];
        NSString *condition = [NSString stringWithFormat:@"user_id = %@ AND peer_id = %@", userIdStr, peerIdStr];
        JYMessage *message = [[JYLocalDataManager sharedInstance] maxIdObjectOfOfClass:JYMessage.class withCondition:condition];
        if (message)
        {
            [self.messageList addObject:message];
        }
    }

    [self _sortMessageList];
    [self _updateTabRedDot];
}

- (void)_sortMessageList
{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"messageId" ascending:NO];
    NSArray *sorted = [self.messageList sortedArrayUsingDescriptors:@[sortDescriptor]];
    self.messageList = [NSMutableArray arrayWithArray:sorted];
}

- (void)_updateTabRedDot
{
    BOOL show = NO;
    for (JYMessage *message in self.messageList)
    {
        show = [message.isUnread boolValue];
        if (show)
        {
            break;
        }
    }

    NSDictionary *info = @{@"index": @(2), @"show": [NSNumber numberWithBool:show]};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidChangeRedDot object:nil userInfo:info];
}

- (NSInteger)_indexOfMessageWithPeerId:(NSNumber *)peerId
{
    uint64_t targetValue = [peerId unsignedLongLongValue];
    NSUInteger count = [self.messageList count];
    for (NSUInteger i = 0; i < count; ++i)
    {
        JYMessage *message = self.messageList[i];
        if ([message.peerId unsignedLongLongValue] == targetValue)
        {
            return i;
        }
    }
    return NSNotFound;
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

- (void)_updateSession:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (!info)
    {
        return;
    }

    id messageObj = [info objectForKey:@"message"];
    if (messageObj == [NSNull null])
    {
        return;
    }

    JYMessage *message = (JYMessage *)messageObj;

    if (!self.isViewLoaded)
    {
        [self.messageList addObject:message];
        [self _updateTabRedDot];
        return;
    }

    NSInteger index = [self _indexOfMessageWithPeerId:message.peerId];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (index != NSNotFound)
        {
            [self.messageList removeObjectAtIndex:index];
        }
        [self.messageList insertObject:message atIndex:0];
        [self.tableView reloadData];
    });

    [self _updateTabRedDot];
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
    JYMessage *message = self.messageList[indexPath.row];

    // delete session
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        [self.messageList removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        [self _updateTabRedDot];
    });

    // delete all the messages in the session
    NSString *userIdStr = [[JYCredential current].userId uint64String];
    NSString *peerIdStr = [message.peerId uint64String];
    NSString *condition = [NSString stringWithFormat:@"user_id = %@ AND peer_id = %@", userIdStr, peerIdStr];

    // delete all cached images
    NSArray *messages = [[JYLocalDataManager sharedInstance] selectObjectsOfClass:JYMessage.class withCondition:condition sort:@"ASC"];
    for (JYMessage *msg in messages)
    {
        if (msg.bodyType == JYMessageBodyTypeImage)
        {
            NSURL *url = [NSURL URLWithString:msg.URL];
            NSString *key = [SDWebImageManager.sharedManager cacheKeyForURL:url];
            [[SDImageCache sharedImageCache] removeImageForKey:key];
        }
    }
    [[JYLocalDataManager sharedInstance] deleteObjectsOfClass:JYMessage.class withCondition:condition];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger number = [self.messageList count];
    return number;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYSessionListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    cell.message = self.messageList[indexPath.row];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    JYSessionListViewCell *cell = (JYSessionListViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [self _showChatViewWithFriend:cell.friend];
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

    deleteAction.backgroundColor = JoyyRedPure;
    return @[deleteAction];
}

@end
