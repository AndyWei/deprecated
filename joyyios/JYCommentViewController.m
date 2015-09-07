//
//  JYCommentViewController.m
//  joyyios
//
//  Created by Ping Yang on 5/20/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <MJRefresh/MJRefresh.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYComment.h"
#import "JYCommentTextView.h"
#import "JYCommentView.h"
#import "JYCommentViewCell.h"
#import "JYCommentViewController.h"

@interface JYCommentViewController ()
@property(nonatomic) BOOL autoShowKeyboard;
@property(nonatomic) JYCommentView *captionView;
@property(nonatomic) JYPost *post;
@property(nonatomic) MJRefreshNormalHeader *header;
@property(nonatomic) MJRefreshAutoNormalFooter *footer;
@property(nonatomic) NSInteger networkThreadCount;
@property(nonatomic) NSMutableArray *commentList;
@property(nonatomic) UIImageView *photoView;
@property(nonatomic) UIView *backgroundView;
@end

static NSString *const kCommentCellIdentifier = @"commentCell";

@implementation JYCommentViewController

- (instancetype)initWithPost:(JYPost *)post withKeyboard:(BOOL)autoShowKeyBoard
{
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self)
    {
        [self.tableView registerClass:[JYCommentViewCell class] forCellReuseIdentifier:kCommentCellIdentifier];
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
    self.view.backgroundColor = JoyyBlack;

    // textInput view
    self.bounces = YES;
    self.shakeToClearEnabled = NO;
    self.keyboardPanningEnabled = YES;
    self.shouldScrollToBottomAfterKeyboardShows = NO;
    self.inverted = NO;

    [self.rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    self.rightButton.tintColor = JoyyBlue;
    self.textInputbar.backgroundColor = JoyyBlack;
    self.textInputbar.autoHideRightButton = NO;
    self.typingIndicatorView.canResignByTouch = YES;

    // tableView
    self.tableView.allowsSelection = NO;
    self.tableView.backgroundColor = JoyyBlack;
    self.tableView.backgroundView = self.backgroundView;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self _showBackgroundImage];
    [self _fetchNewComments];

    self.tableView.header = self.header;
    self.tableView.footer = self.footer;

    self.captionView.caption = self.post.caption;
    self.tableView.tableHeaderView = self.captionView;

    if (self.autoShowKeyboard)
    {
        [self.textView becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self _updateRecentCommentsOfPost];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
}

// pull-down-to-refresh header
- (MJRefreshNormalHeader *)header
{
    if (!_header)
    {
        _header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(_fetchOldComments)];
        _header.lastUpdatedTimeLabel.hidden = YES;
        _header.stateLabel.hidden = YES;
        _header.backgroundColor = JoyyBlack50;
    }
    return _header;
}

// pull-up-to-refresh footer
- (MJRefreshAutoNormalFooter *)footer
{
    if (!_footer)
    {
        _footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(_fetchNewComments)];
        _footer.refreshingTitleHidden = YES;
        _footer.stateLabel.hidden = YES;
        _footer.backgroundColor = JoyyBlack50;
    }
    return _footer;
}

- (UIView *)backgroundView
{
    if (!_backgroundView)
    {
        _backgroundView = [[UIView alloc] initWithFrame:self.tableView.frame];
        [_backgroundView addSubview:self.photoView];
    }
    return _backgroundView;
}

- (UIImageView *)photoView
{
    if (!_photoView)
    {
        CGFloat y = STATUS_BAR_HEIGHT + NAVIGATION_BAR_HEIGHT;
        _photoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, y, SCREEN_WIDTH, SCREEN_WIDTH)];
        _photoView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _photoView;
}

- (void)_showBackgroundImage
{
    // Fetch network image
    NSURL *url = [NSURL URLWithString:_post.url];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    __weak typeof(self) weakSelf = self;
    [self.photoView setImageWithURLRequest:request
                          placeholderImage:nil
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
     {
         weakSelf.photoView.image = image;

     } failure:nil];
}

- (JYCommentView *)captionView
{
    if (!_captionView)
    {
        _captionView = [[JYCommentView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0)];
    }
    return _captionView;
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

- (void)_updateRecentCommentsOfPost
{
    NSInteger totalComment = self.commentList.count;
    NSInteger start = MAX(0, totalComment - 3);
    NSMutableArray *commentList = [NSMutableArray new];
    for (NSInteger i = start; i < totalComment; ++i)
    {
        JYComment *comment = self.commentList[i];
        [commentList addObject:comment];
    }
    self.post.commentList = commentList;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.commentList.count + 5; // Use 5 dummy cell to cover the background photo with JoyyBlack50 color
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYCommentViewCell *cell =
    (JYCommentViewCell *)[tableView dequeueReusableCellWithIdentifier:kCommentCellIdentifier forIndexPath:indexPath];

    if (indexPath.row < self.commentList.count)
    {
        cell.comment = self.commentList[indexPath.row];
    }
    else
    {
        cell.comment = nil;
    }

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYComment *comment = nil;
    if (indexPath.row < self.commentList.count)
    {
        comment = self.commentList[indexPath.row];
    }
    return [JYCommentViewCell heightForComment:comment];
}

#pragma mark - Maintain Table

- (void)_updateTableWithComments:(NSArray *)list toEnd:(BOOL)toEnd
{
    if (!list.count)
    {
        return;
    }

    BOOL firstLoad = self.commentList.count == 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _addCommentsFromList:list toEnd:toEnd];

        if (firstLoad)
        {
            [self.tableView reloadData];
            [self _scrollTableViewToBottom];
        }
        else
        {
            CGSize beforeContentSize = self.tableView.contentSize;
            [self.tableView reloadData];
            CGSize afterContentSize = self.tableView.contentSize;

            CGPoint afterContentOffset = self.tableView.contentOffset;
            CGPoint newContentOffset = CGPointMake(afterContentOffset.x, afterContentOffset.y + afterContentSize.height - beforeContentSize.height);
            self.tableView.contentOffset = newContentOffset;
        }
    });
}

- (void)_addCommentsFromList:(NSArray *)list toEnd:(BOOL)toEnd
{
    if (!list.count)
    {
        return;
    }

    // The items in commentsList are DESC sorted by id
    if (toEnd)
    {
        for (NSDictionary *dict in [list reverseObjectEnumerator])
        {
            JYComment *comment = [[JYComment alloc] initWithDictionary:dict];
            [self.commentList addObject:comment];
        }
    }
    else
    {
        for (NSDictionary *dict in list)
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

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"comment"];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:[self _parametersForCreatingComment]
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
    NSString *url = [NSString apiURLWithPath:@"comment"];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:[self _parametersForCommentOfPost:toEnd]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {

             NSLog(@"comment GET success responseObject: %@", responseObject);
             [weakSelf _updateTableWithComments:responseObject toEnd:toEnd];
             [weakSelf _networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf _networkThreadEnd];
         }
     ];
}

- (NSDictionary *)_parametersForCreatingComment
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:@(self.post.postId) forKey:@"post"];
    [parameters setValue:self.textView.text forKey:@"content"];

    return parameters;
}

- (NSDictionary *)_parametersForCommentOfPost:(BOOL)toEnd
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:@(self.post.postId) forKey:@"post"];

    if (self.commentList.count > 0)
    {
        if (toEnd)
        {
            JYComment *comment = self.commentList.lastObject;
            [parameters setValue:@(comment.timestamp) forKey:@"after"];
        }
        else
        {
            JYComment *comment = self.commentList.firstObject;
            [parameters setValue:@(comment.timestamp) forKey:@"before"];
        }
    }

    return parameters;
}

@end
