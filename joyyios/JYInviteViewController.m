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
#import "JYInvite.h"
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

#pragma mark - JYUserBaseCellDelegate

- (void)didTapActionButtonOnCell:(JYUserBaseCell *)cell
{
    if (!cell || !cell.user)
    {
        return;
    }

    JYInvite *invite = (JYInvite *)cell.user;
    [self _acceptInvite:invite];
}

#pragma mark - Network

- (void)_acceptInvite:(JYInvite *)invite
{
    if (!invite)
    {
        return;
    }

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"invite/accept"];
    NSDictionary *parameters = [self _parametersForAcceptingInvite:invite];

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:parameters
         progress:nil
          success:^(NSURLSessionTask *operation, id responseObject) {
              NSLog(@"POST accept/invite success. responseObject = %@", responseObject);

              if ([responseObject isKindOfClass:NSDictionary.class])
              {
                  NSDictionary *dict = (NSDictionary *)responseObject;
                  NSError *error = nil;
                  JYFriend *friend = (JYFriend *)[MTLJSONAdapter modelOfClass:JYFriend.class fromJSONDictionary:dict error:&error];
                  [weakSelf _didConvertInvite:invite toFriend:friend];
              }
          }
          failure:^(NSURLSessionTask *operation, NSError *error) {
              NSLog(@"POST accept/invite fail. error = %@", error);
          }
     ];
}

- (NSDictionary *)_parametersForAcceptingInvite:(JYInvite *)invite
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:invite.username forKey:@"fname"];
    [parameters setObject:[invite.inviteId uint64Number] forKey:@"id"];
    [parameters setObject:[invite.userId uint64Number] forKey:@"fid"];
    [parameters setObject:[invite.yrsNumber uint64Number] forKey:@"fyrs"];

    // YRS
    uint64_t yrsValue = [JYCredential current].yrsValue;
    [parameters setObject:@(yrsValue) forKey:@"yrs"];

    return parameters;
}

- (void)_didConvertInvite:(JYInvite *)invite toFriend:(JYFriend *)friend
{
    [self _removeInvite:invite];

    NSDictionary *info = @{@"friend": friend};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidAddFriend object:nil userInfo:info];
}

- (void)_removeInvite:(JYInvite *)invite
{
    [[JYLocalDataManager sharedInstance] deleteObject:invite ofClass:JYInvite.class];

    NSUInteger index = [self.inviteList indexOfObject:invite];
    if (index == NSNotFound)
    {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.inviteList removeObjectAtIndex:index];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    });
}

@end
