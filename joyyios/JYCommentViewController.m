//
//  JYCommentViewController.m
//  joyyios
//
//  Created by Ping Yang on 5/20/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <MJRefresh/MJRefresh.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYComment.h"
#import "JYCommentTextView.h"
#import "JYCommentViewCell.h"
#import "JYCommentViewController.h"
#import "JYUser.h"

@interface JYCommentViewController ()

@property(nonatomic) NSInteger networkThreadCount;
@property(nonatomic) JYPost *post;
@property(nonatomic) NSMutableArray *commentList;
@property(nonatomic) BOOL autoShowKeyboard;

@end

static NSString *const kCommentCellIdentifier = @"commentCell";

@implementation JYCommentViewController

- (instancetype)initWithPost:(JYPost *)post withKeyboard:(BOOL)autoShowKeyBoard
{
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self)
    {
        [self registerClassForTextView:[JYCommentTextView class]];
        _post = post;
        _autoShowKeyboard = autoShowKeyBoard;
        _networkThreadCount = 0;
        _commentList = [NSMutableArray new];
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
    self.title = NSLocalizedString(@"COMMENTS", nil);
    self.view.backgroundColor = JoyyWhite;
    //
    self.bounces = YES;
    self.shakeToClearEnabled = NO;
    self.keyboardPanningEnabled = YES;
    self.shouldScrollToBottomAfterKeyboardShows = NO;
    self.inverted = NO;

    [self.rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    self.rightButton.tintColor = JoyyBlue;
    self.textInputbar.autoHideRightButton = NO;
    self.typingIndicatorView.canResignByTouch = YES;

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[JYCommentViewCell class] forCellReuseIdentifier:kCommentCellIdentifier];

    // Setup the pull-down-to-refresh header
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(_fetchOldComments)];
    header.lastUpdatedTimeLabel.hidden = YES;
    header.stateLabel.hidden = YES;
    self.tableView.header = header;

    // Setup the pull-up-to-refresh footer
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(_fetchNewComments)];
    footer.refreshingTitleHidden = YES;
    footer.stateLabel.hidden = YES;
    self.tableView.footer = footer;

    [self _scrollTableViewToBottom];
    if (self.autoShowKeyboard)
    {
        [self.textView becomeFirstResponder];
    }

    [self _fetchNewComments];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self _updatePostBrief];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{

}

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
        [self.tableView.header endRefreshing];
        [self.tableView.footer endRefreshing];
    }
}

- (void)_scrollTableViewToBottom
{
    if (self.commentList.count > 0)
    {
        NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:self.commentList.count-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastIndex atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)_updatePostBrief
{
    NSInteger totalComment = self.commentList.count;
    NSInteger start = MAX(0, totalComment - 3);
    NSMutableArray *commentTextList = [NSMutableArray new];
    for (NSInteger i = start; i < totalComment; ++i)
    {
        JYComment *comment = self.commentList[i];
        [commentTextList addObject:comment.contentString];
    }
    self.post.commentTextList = commentTextList;
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
    JYCommentViewCell *cell =
    (JYCommentViewCell *)[tableView dequeueReusableCellWithIdentifier:kCommentCellIdentifier forIndexPath:indexPath];

    cell.comment = self.commentList[indexPath.row];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [JYCommentViewCell heightForComment:self.commentList[indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    return [JYOrderCard heightForOrder:self.order withAddress:NO andBid:YES];
//}
//
//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    CGFloat height = [JYOrderCard heightForOrder:self.order withAddress:NO andBid:YES];
//
//    JYOrderCard *card = [[JYOrderCard alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), height)];
//    card.tinyLabelsHidden = NO;
//    [card presentOrder:self.order withAddress:NO andBid:YES];
//    card.backgroundColor = self.order.bidColor;
//    return card;
//}

#pragma mark - Maintain Table

- (void)_updateTableWithComments:(NSArray *)list toEnd:(BOOL)toEnd
{
    if (!list.count)
    {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self _addCommentsFromList:list toEnd:toEnd];
        [self.tableView reloadData];
    });
}

- (void)_addCommentsFromList:(NSArray *)list toEnd:(BOOL)toEnd
{
    if (!list.count)
    {
        return;
    }

    // The items in commentsList are ASC sorted by id
    if (toEnd)
    {
        for (NSDictionary *dict in list)
        {
            JYComment *comment = [[JYComment alloc] initWithDictionary:dict];
            [self.commentList addObject:comment];
        }
    }
    else
    {
        for (NSDictionary *dict in [list reverseObjectEnumerator])
        {
            JYComment *comment = [[JYComment alloc] initWithDictionary:dict];
            [self.commentList insertObject:comment atIndex:0];
        }
    }
}

#pragma mark - Overriden Method

// Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
- (void)didPressRightButton:(id)sender
{
    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    [self.textView refreshFirstResponder];

    [self _postComment];
    [super didPressRightButton:sender];
}

#pragma mark - Network

- (void)_fetchOldComments
{
    [self _fetchCommentsToEnd:NO];
}

- (void)_fetchNewComments
{
    [self _fetchCommentsToEnd:YES];
}

- (void)_postComment
{
    [self _networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"comment"];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:[self _httpPostCommentParameters]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"Comment POST Success responseObject: %@", responseObject);

              [weakSelf _networkThreadEnd];
              NSUInteger commentCount = [responseObject unsignedIntegerValueForKey:@"comments"];
              weakSelf.post.commentCount = commentCount;

              [weakSelf _fetchNewComments];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {

              [weakSelf _networkThreadEnd];

              [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                             message:error.localizedDescription
                     backgroundColor:FlatYellow
                           textColor:FlatBlack
                                time:5];
          }
     ];
}

- (void)_fetchCommentsToEnd:(BOOL)toEnd
{
    if (self.networkThreadCount > 0)
    {
        return;
    }
    [self _networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"comment"];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:[self _httpGetCommentsParameters:toEnd]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {

//             NSLog(@"comment GET success responseObject: %@", responseObject);
             [weakSelf _updateTableWithComments:responseObject toEnd:toEnd];

             NSDictionary *info = @{@"post": self.post};
             [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidCreateComment object:nil userInfo:info];

             [weakSelf _networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf _networkThreadEnd];
         }
     ];
}

- (NSDictionary *)_httpPostCommentParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:@(self.post.postId) forKey:@"post"];
    [parameters setValue:self.textView.text forKey:@"content"];

    return parameters;
}

- (NSDictionary *)_httpGetCommentsParameters:(BOOL)toEnd
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:@(self.post.postId) forKey:@"post"];

    if (self.commentList.count > 0)
    {
        if (toEnd)
        {
            JYComment *comment = self.commentList.lastObject;
            [parameters setValue:@(comment.commentId) forKey:@"after"];
        }
        else
        {
            JYComment *comment = self.commentList.firstObject;
            [parameters setValue:@(comment.commentId) forKey:@"before"];
        }
    }

    return parameters;
}

@end
