//
//  JYWinkViewController.m
//  joyyios
//
//  Created by Ping Yang on 12/23/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "JYCredential.h"
#import "JYFriendManager.h"
#import "JYLocalDataManager.h"
#import "JYUserlineViewController.h"
#import "JYWink.h"
#import "JYWinkCell.h"
#import "JYWinkViewController.h"

@interface JYWinkViewController () <JYUserBaseCellDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) NSMutableArray *winkList;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kCellIdentifier = @"winkCell";

@implementation JYWinkViewController

- (instancetype)initWithWinkList:(NSMutableArray *)winkList
{
    if (self = [super init])
    {
        self.winkList = winkList;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Winks", nil);

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

        [_tableView registerClass:[JYWinkCell class] forCellReuseIdentifier:kCellIdentifier];
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.winkList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYWinkCell *cell =
    (JYWinkCell *)[tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];

    JYUser *user = [self.winkList objectAtIndex:indexPath.row];
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

    JYUser *user = [self.winkList objectAtIndex:indexPath.row];
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

    JYWink *wink = (JYWink *)cell.user;
    [self _acceptWink:wink];
}

#pragma mark - Network

- (void)_acceptWink:(JYWink *)wink
{
    if (!wink)
    {
        return;
    }

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"wink/accept"];
    NSDictionary *parameters = [self _parametersForAcceptingWink:wink];

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:parameters
         progress:nil
          success:^(NSURLSessionTask *operation, id responseObject) {
              NSLog(@"POST wink/accept success. responseObject = %@", responseObject);

              if ([responseObject isKindOfClass:NSDictionary.class])
              {
                  NSDictionary *dict = (NSDictionary *)responseObject;
                  NSError *error = nil;
                  JYFriend *friend = (JYFriend *)[MTLJSONAdapter modelOfClass:JYFriend.class fromJSONDictionary:dict error:&error];
                  [weakSelf _didConvertWink:wink toFriend:friend];
              }
          }
          failure:^(NSURLSessionTask *operation, NSError *error) {
              NSLog(@"POST wink/accept fail. error = %@", error);
          }
     ];
}

- (NSDictionary *)_parametersForAcceptingWink:(JYWink *)wink
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:wink.username forKey:@"fname"];
    [parameters setObject:[wink.winkId uint64Number] forKey:@"id"];
    [parameters setObject:[wink.userId uint64Number] forKey:@"fid"];
    [parameters setObject:[wink.yrsNumber uint64Number] forKey:@"fyrs"];

    // YRS
    uint64_t yrsValue = [JYCredential current].yrsValue;
    [parameters setObject:@(yrsValue) forKey:@"yrs"];

    return parameters;
}

- (void)_didConvertWink:(JYWink *)wink toFriend:(JYFriend *)friend
{
    [self _removeWink:wink];

    NSDictionary *info = @{@"friend": friend};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidAddFriend object:nil userInfo:info];
}

- (void)_removeWink:(JYWink *)wink
{
    [[JYLocalDataManager sharedInstance] deleteObject:wink ofClass:JYWink.class];

    NSUInteger index = [self.winkList indexOfObject:wink];
    if (index == NSNotFound)
    {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.winkList removeObjectAtIndex:index];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    });
}

@end

