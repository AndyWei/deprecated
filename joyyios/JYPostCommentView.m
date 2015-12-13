//
//  JYPostCommentView.m
//  joyyios
//
//  Created by Ping Yang on 11/26/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYComment.h"
#import "JYPost.h"
#import "JYPostCommentView.h"
#import "JYPostCommentCell.h"

@interface JYPostCommentView () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic) NSMutableArray *commentList;
@property (nonatomic) JYPostCommentCell *sizingCell;
@end

static NSString *const kPostCommentCellIdentifier = @"postCommentCell";

@implementation JYPostCommentView

- (instancetype)init
{
    if (self = [super initWithFrame:CGRectZero style:UITableViewStylePlain])
    {
        self.allowsSelection = YES;
        self.bounces = NO;
        self.dataSource = self;
        self.delegate = self;
        self.scrollEnabled = NO;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.translatesAutoresizingMaskIntoConstraints = NO;

        [self registerClass:[JYPostCommentCell class] forCellReuseIdentifier:kPostCommentCellIdentifier];
    }
    return self;
}

- (void)setPost:(JYPost *)post
{
    _post = post;
    _commentList = [NSMutableArray new];

    if (!post)
    {
        return;
    }

    for (JYComment *comment in post.commentList)
    {
        if (![comment isLike])
        {
            [_commentList addObject:comment];
        }
    }
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
    JYPostCommentCell *cell =
    (JYPostCommentCell *)[tableView dequeueReusableCellWithIdentifier:kPostCommentCellIdentifier forIndexPath:indexPath];

    cell.comment = self.commentList[indexPath.row];

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

#pragma mark - UITableView Delegate

// This is a table-in-table view, so the height must be calculated manually and can not use the fancy UITableViewAutomaticDimension
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.sizingCell)
    {
        self.sizingCell = [[JYPostCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"JYPostCommentViewCell_sizing"];
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

// This is a table-in-table view, so the estimated height must be acurate and can not use the fancy UITableViewAutomaticDimension
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    JYComment *comment = (JYComment *)self.commentList[indexPath.row];
    NSDictionary *info = @{@"post": self.post, @"comment": comment};
    if ([comment isMine])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeleteComment object:nil userInfo:info];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCreateComment object:nil userInfo:info];
    }
}

@end

