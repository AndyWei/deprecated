//
//  JYProfileViewController.m
//  joyyios
//
//  Created by Ping Yang on 12/23/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <MJRefresh/MJRefresh.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYButton.h"
#import "JYAvatarCreator.h"
#import "JYFilename.h"
#import "JYFriendManager.h"
#import "JYFriendViewController.h"
#import "JYInvite.h"
#import "JYInviteViewController.h"
#import "JYLocalDataManager.h"
#import "JYProfileCardView.h"
#import "JYProfileDataManager.h"
#import "JYProfileViewController.h"
#import "JYPost.h"
#import "JYUserlineCell.h"
#import "JYWink.h"
#import "JYWinkViewController.h"
#import "NSNumber+Joyy.h"

@interface JYProfileViewController () <JYAvatarCreatorDelegate, JYProfileCardViewDelegate, JYProfileDataManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) JYAvatarCreator *avatarCreator;
@property (nonatomic) JYProfileCardView *cardView;
@property (nonatomic) JYProfileDataManager *dataManager;
@property (nonatomic) NSMutableArray *friendList;
@property (nonatomic) NSMutableArray *inviteList;
@property (nonatomic) NSMutableArray *postList;
@property (nonatomic) NSMutableArray *winkList;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kCellIdentifier = @"profileUserlineCell";

@implementation JYProfileViewController

- (instancetype)init
{
    if (self = [super init])
    {
        self.postList = [NSMutableArray new];
        self.friendList = [NSMutableArray new];
        self.inviteList = [[JYLocalDataManager sharedInstance] selectObjectsOfClass:JYInvite.class limit:200 sort:@"DESC"];
        self.winkList = [[JYLocalDataManager sharedInstance] selectObjectsOfClass:JYWink.class limit:500 sort:@"DESC"];

        self.dataManager = [JYProfileDataManager new];
        self.dataManager.delegate = self;
        [self.dataManager start];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Me", nil);
    self.navigationController.navigationBar.translucent = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didAddFriend:) name:kNotificationDidAddFriend object:nil];
    [self.view addSubview:self.tableView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.cardView.inviteCount = [self.inviteList count];
    self.cardView.winkCount = [self.winkList count];
    self.cardView.friendCount = [self.friendList count];

    [self.cardView setNeedsLayout];
    [self.cardView layoutIfNeeded];
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
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsVerticalScrollIndicator = YES;
        _tableView.tableHeaderView = self.cardView;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 415;
        [_tableView registerClass:[JYUserlineCell class] forCellReuseIdentifier:kCellIdentifier];

        // Setup the pull-up-to-refresh footer
        MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(_fetchUserline)];
        footer.refreshingTitleHidden = YES;
        footer.stateLabel.hidden = YES;
        _tableView.mj_footer = footer;
    }
    return _tableView;
}

- (JYProfileCardView *)cardView
{
    if (!_cardView)
    {
        _cardView = [JYProfileCardView new];
        _cardView.delegate = self;
    }
    return _cardView;
}

- (JYAvatarCreator *)avatarCreator
{
    if (!_avatarCreator)
    {
        _avatarCreator = [[JYAvatarCreator alloc] initWithViewController:self];
        _avatarCreator.delegate = self;
    }
    return _avatarCreator;
}

- (void)setInviteList:(NSMutableArray *)inviteList
{
    _inviteList = inviteList;
    self.cardView.inviteCount = [_inviteList count];
    [self.cardView setNeedsLayout];
    [self.cardView layoutIfNeeded];

    NSUInteger count = [_winkList count] + [_inviteList count];
    [self _showRedDot:(count > 0)];
}

- (void)setWinkList:(NSMutableArray *)winkList
{
    _winkList = winkList;
    self.cardView.winkCount = [_winkList count];
    [self.cardView setNeedsLayout];
    [self.cardView layoutIfNeeded];

    NSUInteger count = [_winkList count] + [_inviteList count];
    [self _showRedDot:(count > 0)];
}

- (void)_showRedDot:(BOOL)show
{
    NSDictionary *info = @{@"index": @(3), @"show": [NSNumber numberWithBool:show]};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidChangeRedDot object:nil userInfo:info];
}

- (void)_fetchUserline
{
    [self.dataManager fetchUserline];
}

#pragma mark - JYProfileCardViewDelegate

- (void)didTapFriendLabelOnView:(JYProfileCardView *)view
{
    if ([self.friendList count] > 0)
    {
        JYFriendViewController *viewController = [[JYFriendViewController alloc] initWithFriendList:self.friendList];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)didTapInviteLabelOnView:(JYProfileCardView *)view
{
    // test only
    JYUser *user = [JYFriend myself];
    self.inviteList = [NSMutableArray new];
    for (int i = 0; i < 10; ++i)
    {
        [self.inviteList addObject:user];
    }
    //

    if ([self.inviteList count] > 0)
    {
        JYInviteViewController *viewController = [[JYInviteViewController alloc] initWithInviteList:self.inviteList];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)didTapWinkLabelOnView:(JYProfileCardView *)view
{
// test only
//    JYUser *user = [JYFriend myself];
//    self.winkList = [NSMutableArray new];
//    for (int i = 0; i < 10; ++i)
//    {
//        [self.winkList addObject:user];
//    }
//

    if ([self.winkList count] > 0)
    {
        JYWinkViewController *viewController = [[JYWinkViewController alloc] initWithWinkList:self.winkList];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)didTapAvatarOnView:(JYProfileCardView *)view
{
    [self.avatarCreator showOptions];
}

#pragma mark - JYAvatarCreatorDelegate

- (void)creator:(JYAvatarCreator *)creator didTakePhoto:(UIImage *)image
{
    self.cardView.avatarImage = image;

    __weak typeof(self) weakSelf = self;
    [self.avatarCreator uploadAvatarImage:image success:^{
        [weakSelf _updateProfileRecord];
    } failure:^(NSError *error) {
        NSString *errorMessage = nil;
        errorMessage = [error.userInfo valueForKey:NSLocalizedDescriptionKey];

        [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                       message:errorMessage
               backgroundColor:FlatYellow
                     textColor:FlatBlack
                          time:5];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.postList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYUserlineCell *cell =
    (JYUserlineCell *)[tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];

    JYPost *post = self.postList[indexPath.row];
    cell.post = post;

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

#pragma mark - UITableView Delegate

#pragma mark - Network

- (void)_updateProfileRecord
{
    NSDictionary *parameters = [self _profileUpdateParameters];
    [self.avatarCreator writeRemoteProfileWithParameters:parameters success:nil failure:nil];
}

- (NSDictionary *)_profileUpdateParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    // phone
    NSString *phoneNumber = [JYCredential current].phoneNumber;
    [parameters setObject:phoneNumber forKey:@"phone"];

    // YRS
    uint64_t yrsValue = [JYCredential current].yrsValue;
    [parameters setObject:@(yrsValue) forKey:@"yrs"];
    [parameters setObject:@YES forKey:@"boardcast"];

    return parameters;
}

#pragma mark - JYProfileDataManagerDelegate

- (void)manager:(JYProfileDataManager *)manager didReceiveFriends:(NSMutableArray *)list
{
    if ([list count] == 0)
    {
        return;
    }

    self.friendList = list;

    self.cardView.friendCount = [list count];
    [self.cardView setNeedsLayout];
    [self.cardView layoutIfNeeded];
}

- (void)manager:(JYProfileDataManager *)manager didReceivePosts:(NSMutableArray *)list
{
    if ([list count] == 0)
    {
        return;
    }

    [self.postList addObjectsFromArray:list];

    if (self.isViewLoaded)
    {
        [self.tableView reloadData];
        [self.tableView.mj_footer endRefreshing];
    }
}

- (void)manager:(JYProfileDataManager *)manager didReceiveInvites:(NSMutableArray *)list
{
    [list addObjectsFromArray:self.inviteList];
    self.inviteList = list;
}

- (void)manager:(JYProfileDataManager *)manager didReceiveWinks:(NSMutableArray *)list
{
    [list addObjectsFromArray:self.winkList];
    self.winkList = list;
}

- (void)manager:(JYProfileDataManager *)manager didReceiveOwnProfile:(JYUser *)me
{
    self.cardView.user = me;
    [self.cardView setNeedsLayout];
    [self.cardView layoutIfNeeded];
}

#pragma mark - Notification handlers

- (void)_didAddFriend:(NSNotification *)notification
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
    uint64_t friendId = [friend.userId unsignedLongLongValue];

    for (JYFriend *oldFriend in self.friendList)
    {
        // avoid duplicate friends
        if ([oldFriend.userId unsignedLongLongValue] == friendId)
        {
            return;
        }
    }

    [self.friendList addObject:friend];
    [[JYFriendManager sharedInstance] receivedFriendList:@[friend]];

    self.cardView.friendCount = [self.friendList count];
    [self.cardView setNeedsLayout];
    [self.cardView layoutIfNeeded];
}

@end
