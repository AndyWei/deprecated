//
//  JYPostCommentView.m
//  joyyios
//
//  Created by Ping Yang on 11/26/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYComment.h"
#import "JYPostCommentView.h"
#import "JYPostCommentViewCell.h"

@interface JYPostCommentView ()
@property (nonatomic) JYPostCommentViewCell *sizingCell;
@end

static NSString *const kPostCommentCellIdentifier = @"postCommentCell";

@implementation JYPostCommentView

- (instancetype)init
{
    if (self = [super initWithFrame:CGRectZero style:UITableViewStylePlain])
    {
        self.dataSource = self;
        self.delegate = self;
        self.estimatedRowHeight = UITableViewAutomaticDimension;
        self.scrollEnabled = NO;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.translatesAutoresizingMaskIntoConstraints = NO;

        [self registerClass:[JYPostCommentViewCell class] forCellReuseIdentifier:kPostCommentCellIdentifier];
    }
    return self;
}

- (void)setCommentList:(NSArray *)commentList
{
    _commentList = commentList;
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
    JYPostCommentViewCell *cell =
    (JYPostCommentViewCell *)[tableView dequeueReusableCellWithIdentifier:kPostCommentCellIdentifier forIndexPath:indexPath];

    cell.comment = self.commentList[indexPath.row];

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)])
    {
        NSOperatingSystemVersion ios8_0_0 = (NSOperatingSystemVersion){8, 0, 0};
        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios8_0_0])
        {
            return UITableViewAutomaticDimension;
        }
    }

    if (!self.sizingCell)
    {
        self.sizingCell = [[JYPostCommentViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"JYPostCommentViewCell_sizing"];
    }

    // Configure sizing cell for this indexPath
    self.sizingCell.comment = self.commentList[indexPath.row];

    // Make sure the constraints have been added to this cell, since it may have just been created from scratch
    [self.sizingCell setNeedsUpdateConstraints];
    [self.sizingCell updateConstraintsIfNeeded];

    self.sizingCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(self.sizingCell.bounds));

    [self.sizingCell setNeedsLayout];
    [self.sizingCell layoutIfNeeded];

    // Get the actual height required for the cell
    CGSize size = [self.sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

    // Add an extra point to the height to account for the cell separator, which is added between the bottom
    // of the cell's contentView and the bottom of the table view cell.
    CGFloat height = size.height;

    return height;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

@end
