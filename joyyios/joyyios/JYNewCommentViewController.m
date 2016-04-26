//
//  JYNewCommentViewController.m
//  joyyios
//
//  Created by Ping Yang on 12/15/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYFriendManager.h"
#import "JYLocalDataManager.h"
#import "JYNewCommentViewController.h"
#import "JYNewCommentCell.h"

@interface JYNewCommentViewController ()
@end

static NSString *const kCellIdentifier = @"newCommentCell";

@implementation JYNewCommentViewController

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Comments", nil);
    self.view.backgroundColor = JoyyBlack;

    // tableView
    self.tableView.backgroundColor = JoyyWhitePure;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 80;
    [self.tableView registerClass:[JYNewCommentCell class] forCellReuseIdentifier:kCellIdentifier];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.commentList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYNewCommentCell *cell =
    (JYNewCommentCell *)[tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];

    cell.comment = self.commentList[indexPath.row];

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
}

@end
