//
//  JYContactViewController.m
//  joyyios
//
//  Created by Ping Yang on 1/5/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>

#import "JYContactCell.h"
#import "JYContactViewController.h"
#import "JYCredential.h"
#import "JYUserlineViewController.h"
#import "NSString+Joyy.h"

@interface JYContactViewController () <JYUserBaseCellDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) NSMutableArray *userList;
@property (nonatomic) NSDictionary *contactDict;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kCellIdentifier = @"contactCell";

@implementation JYContactViewController

- (instancetype)initWithUserList:(NSMutableArray *)userList contactDictionay:(NSDictionary *)contactDict
{
    if (self = [super init])
    {
        self.userList = userList;
        self.contactDict = contactDict;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Contacts", nil);

    self.navigationController.navigationBar.translucent = YES;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_close)];

    [self.view addSubview:self.tableView];
}

- (void)_close
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;

        _tableView.sectionIndexBackgroundColor = ClearColor;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = YES;

        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 80;

        [_tableView registerClass:[JYContactCell class] forCellReuseIdentifier:kCellIdentifier];
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.userList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYContactCell *cell =
    (JYContactCell *)[tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];

    JYUser *user = [self.userList objectAtIndex:indexPath.row];
    cell.user = user;
    cell.contactName = [self.contactDict objectForKey:user.phoneNumber];
    cell.delegate = self;

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    JYUser *user = [self.userList objectAtIndex:indexPath.row];
    JYUserlineViewController *viewController = [[JYUserlineViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - JYUserBaseCellDelegate

- (void)didTapActionButtonOnCell:(JYUserBaseCell *)cell
{
    if (!cell || !cell.user)
    {
        return;
    }

    JYUser *user = cell.user;

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"invite/create"];
    NSDictionary *parameters = [self _parametersForInvitingUser:user];

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:parameters
          success:^(NSURLSessionTask *operation, id responseObject) {
              NSLog(@"POST invite success. that username = %@", user.username);
              [weakSelf _didInviteUser:user];
          }
          failure:^(NSURLSessionTask *operation, NSError *error) {
              NSLog(@"POST invite fail. error = %@", error);
          }
     ];
}

- (NSDictionary *)_parametersForInvitingUser:(JYUser *)user
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    [parameters setObject:user.username forKey:@"fname"];
    [parameters setObject:@([user.userId unsignedLongLongValue]) forKey:@"fid"];
    [parameters setObject:@(user.yrsValue) forKey:@"fyrs"];
    [parameters setObject:@([JYCredential current].yrsValue) forKey:@"yrs"];

    return parameters;
}

- (void)_didInviteUser:(JYUser *)user
{
    NSInteger index = [self.userList indexOfObject:user];
    if (index == NSNotFound)
    {
        return;
    }

    [self.userList removeObjectAtIndex:index];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];

    if ([self.userList count] == 0)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self _close];
        });
    }
}

@end
