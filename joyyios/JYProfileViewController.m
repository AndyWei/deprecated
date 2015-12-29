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

#import "JYMonth.h"
#import "JYButton.h"
#import "JYAvatarCreator.h"
#import "JYComment.h"
#import "JYCommentViewController.h"
#import "JYFilename.h"
#import "JYFriendManager.h"
#import "JYFriendViewController.h"
#import "JYLocalDataManager.h"
#import "JYPhotoCaptionViewController.h"
#import "JYProfileCardView.h"
#import "JYProfileViewController.h"
#import "JYPost.h"
#import "JYUserlineCell.h"
#import "JYWinkViewController.h"

@interface JYProfileViewController () <JYAvatarCreatorDelegate, JYProfileCardViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) JYAvatarCreator *avatarCreator;
@property (nonatomic) JYMonth *month;
@property (nonatomic) JYUser *user;
@property (nonatomic) JYProfileCardView *cardView;
@property (nonatomic) NSInteger networkThreadCount;
@property (nonatomic) NSMutableArray *friendList;
@property (nonatomic) NSMutableArray *postList;
@property (nonatomic) NSMutableArray *winkList;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kCellIdentifier = @"profileUserlineCell";

@implementation JYProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Me", nil);
    self.navigationController.navigationBar.translucent = YES;

    self.networkThreadCount = 0;
    self.postList = [NSMutableArray new];
    self.month = [[JYMonth alloc] initWithDate:[NSDate date]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_apiTokenReady) name:kNotificationAPITokenReady object:nil];

    self.user = [JYFriend myself];

    if (self.user)
    {
        [self _initSubViews];
    }
}

- (void)_initSubViews
{
    [self.view addSubview:self.tableView];

    [self _fetchFriends];
//    [self _fetchWinks];
    [self _fetchUserline];
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
        _cardView.user = self.user;
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_apiTokenReady
{
    if (!self.user)
    {
        self.user = [JYFriend myself];
        [self _initSubViews];
    }
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

- (void)didTapContactLabelOnView:(JYProfileCardView *)view
{
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
    [self.avatarCreator uploadAvatarImage:image success:^{
        
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

#pragma mark - Maintain table

- (void)_receivedOldPosts:(NSMutableArray *)postList
{
    if ([postList count] == 0) // no more old post, do nothing
    {
        return;
    }

    [self.postList addObjectsFromArray:postList];
    [self.tableView reloadData];
    [self.tableView.mj_footer endRefreshing];
}

#pragma mark - Network

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
        [self.tableView.mj_footer endRefreshing];
    }
}

- (void)_fetchUserline
{
    if (self.networkThreadCount > 0)
    {
        return;
    }

    uint64_t monthValue = self.month.value;
    self.month = [self.month prev];
    [self _fetchUserlineOfMonth:monthValue];
}

- (void)_fetchUserlineOfMonth:(uint64_t)month
{
    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    NSString *url = [NSString apiURLWithPath:@"post/userline"];
    NSDictionary *parameters = @{@"userid": @([self.user.userId unsignedLongLongValue]), @"month": @(month)};

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"post/userline fetch success responseObject: %@", responseObject);

             // the post json is in ASC order, so iterate reversely
             NSMutableArray *postList = [NSMutableArray new];
             for (NSDictionary *dict in [responseObject reverseObjectEnumerator])
             {
                 NSError *error = nil;
                 JYPost *post = (JYPost *)[MTLJSONAdapter modelOfClass:JYPost.class fromJSONDictionary:dict error:&error];
                 if (post)
                 {
                     [postList addObject:post];
                 }
             }

             [weakSelf _receivedOldPosts:postList];
             [weakSelf _networkThreadEnd];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"Error: post/userline fetch failed with error: %@", error);
             [weakSelf _networkThreadEnd];
         }
     ];
}

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

//              test only
//                 JYUser *user = [JYFriend myself];
//                 for (int i = 0; i < 10; ++i)
//                 {
//                     [friendList addObject:user];
//                 }
//

             weakSelf.friendList = friendList;
             weakSelf.cardView.friendCount = [friendList count];
             [[JYFriendManager sharedInstance] receivedFriendList:friendList];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"GET friends error: %@", error);
         }];
}

- (void)_fetchWinks
{
    NSString *url = [NSString apiURLWithPath:@"winks"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:nil
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"GET winks Success");

             NSMutableArray *winkList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 NSError *error = nil;
                 JYUser *user = (JYUser *)[MTLJSONAdapter modelOfClass:JYUser.class fromJSONDictionary:dict error:&error];
                 if (user)
                 {
                     [winkList addObject:user];
                 }
             }
             weakSelf.winkList = winkList;
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"GET winks error: %@", error);
         }];
}

@end
