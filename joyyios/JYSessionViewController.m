//
//  JYSessionViewController.m
//  joyyios
//
//  Created by Ping Yang on 2/15/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <MJRefresh/MJRefresh.h>

#import "JYLocalDataManager.h"
#import "JYMessageTextCell.h"
#import "JYMessageIncomingMediaCell.h"
#import "JYMessageIncomingTextCell.h"
#import "JYMessageOutgoingMediaCell.h"
#import "JYMessageOutgoingTextCell.h"
#import "JYSessionViewController.h"
#import "JYXmppManager.h"

@interface JYSessionViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic) NSMutableArray *messageList;
@property (nonatomic) XMPPJID *thatJID;
@end

static NSString *const kIncomingMediaCell = @"incomingMediaCell";
static NSString *const kIncomingTextCell = @"incomingTextCell";
static NSString *const kOutgoingMediaCell = @"outgoingMediaCell";
static NSString *const kOutgoingTextCell = @"outgoingTextCell";

@implementation JYSessionViewController

- (instancetype)init
{
    if (self = [super initWithTableViewStyle:UITableViewStylePlain])
    {
        self.inverted = NO;
    }
    return self;
}

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self _reloadMessages];
    [self _configTableView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [JYXmppManager sharedInstance].currentRemoteJid = self.thatJID;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [JYXmppManager sharedInstance].currentRemoteJid = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Properties

- (XMPPJID *)thatJID
{
    if (!_thatJID)
    {
        NSString *friendUserId = [self.friend.userId uint64String];
        _thatJID = [JYXmppManager jidWithUserId:friendUserId];
    }
    return _thatJID;
}

- (void)_reloadMessages
{
    // Start load data
    NSString *friendUserId = [self.friend.userId uint64String];
    NSString *senderId = [[JYCredential current].userId uint64String];
//    NSString *condition = [NSString stringWithFormat:@"user_id = %@ AND peer_id = %@", senderId, friendUserId];
//    self.messageList = [[JYLocalDataManager sharedInstance] selectObjectsOfClass:JYMessage.class withCondition:condition sort:@"ASC"];

    NSString *condition = [NSString stringWithFormat:@"user_id = %@ AND peer_id = %@", senderId, friendUserId];

    NSArray *array = [[JYLocalDataManager sharedInstance] selectObjectsOfClass:JYMessage.class withCondition:condition sort:@"DESC LIMIT 80"];
    self.messageList = [NSMutableArray arrayWithArray:[[array reverseObjectEnumerator] allObjects]];


    // mark all unread messages as read
    NSInteger delta = 0;
    for (JYMessage *message in self.messageList)
    {
        if ([message.isUnread boolValue])
        {
            message.isUnread = [NSNumber numberWithBool:NO];
            [[JYLocalDataManager sharedInstance] updateObject:message ofClass:JYMessage.class];
            --delta;
        }
    }

    if (delta != 0)
    {
        [self _updateBadgeCountWithDelta:delta];
    }
}

- (void)_updateBadgeCountWithDelta:(NSInteger)delta
{
    NSDictionary *info = @{@"delta": @(delta)};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateBadgeCount object:nil userInfo:info];
}

- (void)_configTableView
{
    self.tableView.estimatedRowHeight = 50;
    self.tableView.backgroundColor = JoyyWhite;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.showsVerticalScrollIndicator = YES;

    [self.tableView registerClass:JYMessageIncomingMediaCell.class forCellReuseIdentifier:kIncomingMediaCell];
    [self.tableView registerClass:JYMessageIncomingTextCell.class forCellReuseIdentifier:kIncomingTextCell];
    [self.tableView registerClass:JYMessageOutgoingMediaCell.class forCellReuseIdentifier:kOutgoingMediaCell];
    [self.tableView registerClass:JYMessageOutgoingTextCell.class forCellReuseIdentifier:kOutgoingTextCell];

        // Setup the pull-up-to-refresh footer
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(_fetchOldMessages)];
    header.stateLabel.hidden = YES;
    self.tableView.mj_header = header;
}

- (void)_fetchOldMessages
{
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messageList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    JYMessage *message = self.messageList[indexPath.row];
    if ([message isMediaMessage])
    {
        CGFloat height = message.displayDimensions.height + 10;
        return height;
    }

    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYMessage *message = self.messageList[indexPath.row];
    NSString *identifier = nil;
    if ([message isOutgoing].boolValue)
    {
        identifier = [message isMediaMessage]? kOutgoingMediaCell: kOutgoingTextCell;
    }
    else
    {
        identifier = [message isMediaMessage]? kIncomingMediaCell: kIncomingTextCell;
    }

    JYMessageCell *cell = (JYMessageCell *)[tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];

    cell.message = message;

    cell.transform = self.tableView.transform;

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

#pragma mark - UITableView Delegate



@end
