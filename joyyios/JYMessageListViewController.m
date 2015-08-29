//
//  JYMessageListViewController.m
//  joyyios
//
//  Created by Ping Yang on 8/27/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYMessageViewController.h"
#import "JYMessageListViewController.h"
#import "JYUser.h"

@interface JYMessageListViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic) UITableView *tableView;
@end

static NSString *const kMessageCellIdentifier = @"messageCell";

@implementation JYMessageListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMessageCellIdentifier];
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMessageCellIdentifier forIndexPath:indexPath];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    // test chat between user 1 and 2
    NSUInteger myUid = [JYUser currentUser].userId;
    NSUInteger personUid = (myUid == 1) ? (indexPath.row + 2) : 1;

    NSDictionary *dict = @{@"id": @(personUid)};
    JYPerson *person = [[JYPerson alloc] initWithDictionary:dict];
    JYMessageViewController *viewController = [JYMessageViewController new];
    viewController.person = person;
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
