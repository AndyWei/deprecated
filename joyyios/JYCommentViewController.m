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
#import <MSWeakTimer/MSWeakTimer.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYButton.h"
#import "JYCommentViewController.h"
#import "JYCommentlineCell.h"
#import "JYFriendManager.h"
#import "JYLocalDataManager.h"


@interface JYCommentViewController ()
@property (nonatomic) JYComment *originalComment;
@property (nonatomic) JYPost *post;
@property (nonatomic) MSWeakTimer *closeTimer;
@property (nonatomic) NSInteger networkThreadCount;
@property (nonatomic) NSMutableArray *commentList;
@property (nonatomic) UIBarButtonItem *closeButtonItem;
@property (nonatomic) UIImageView *photoView;
@property (nonatomic) UIView *backgroundView;
@end

static NSString *const kCommentlineCellIdentifier = @"commentlineCell";

@implementation JYCommentViewController

- (instancetype)initWithPost:(JYPost *)post comment:(JYComment *)originalComment
{
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self)
    {
        [self.tableView registerClass:[JYCommentlineCell class] forCellReuseIdentifier:kCommentlineCellIdentifier];

        self.post = post;
        self.originalComment = originalComment;
        self.networkThreadCount = 0;

        [self _updatePlaceholder];
        [self _initDataSource];
        [self _fetchNewComments];
    }
    return self;
}

- (void)_initDataSource
{
    self.commentList = [NSMutableArray new];

    // enwrap the caption text as a comment
    if ([_post.caption length] != 0)
    {
        JYComment *captionComment = [[JYComment alloc] initWithOwnerId:_post.ownerId content:_post.caption];
        [_commentList addObject:captionComment];
    }

    for (JYComment *comment in self.post.commentList)
    {
        if (![comment isLike])
        {
            [self.commentList addObject:comment];
        }
    }
}

- (void)_updatePlaceholder
{
    if (self.originalComment) // comment on another comment
    {
        JYFriend *owner = [[JYFriendManager sharedInstance] friendWithId:self.originalComment.ownerId];
        NSString *replyText = NSLocalizedString(@"Reply to", nil);
        self.textInputbar.textView.placeholder = [NSString stringWithFormat:@"%@ %@:", replyText, owner.username];
    }
    else // comment to post
    {
        self.textInputbar.textView.placeholder = NSLocalizedString(@"Add comment:", nil);
    }
}

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Comments", nil);
    self.view.backgroundColor = JoyyBlack;
    self.navigationItem.leftBarButtonItem = self.closeButtonItem;

    // textInput view
    self.bounces = YES;
    self.shakeToClearEnabled = NO;
    self.keyboardPanningEnabled = YES;
    self.shouldScrollToBottomAfterKeyboardShows = NO;
    self.inverted = NO;

    [self.rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    self.rightButton.tintColor = JoyyBlue;
    self.textInputbar.autoHideRightButton = NO;
    self.typingIndicatorView.canResignByTouch = YES;

    // tableView
    self.tableView.allowsSelection = NO;
    self.tableView.backgroundColor = JoyyBlack;
    self.tableView.backgroundView = self.backgroundView;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;

    [self _showBackgroundImage];

    [self.textView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)_close
{
    CATransition *transition = [CATransition animation];
    transition.duration = 0.05;
    transition.type = kCATransitionFade;
    transition.subtype = kCATransitionFromTop;

    [self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)_closeInSecs:(NSTimeInterval)seconds
{
    [self _stopCloseTimer];
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.closeTimer = [MSWeakTimer scheduledTimerWithTimeInterval:seconds
                                                            target:self
                                                          selector:@selector(_close)
                                                          userInfo:nil
                                                           repeats:NO
                                                     dispatchQueue:queue];
}

- (void)_stopCloseTimer
{
    if (self.closeTimer)
    {
        [self.closeTimer invalidate];
        self.closeTimer = nil;
    }
}

- (UIBarButtonItem *)closeButtonItem
{
    if (!_closeButtonItem)
    {
        CGRect frame =  CGRectMake(-10, 0, 20, 20);
        JYButton *button = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
        button.imageView.image = [UIImage imageNamed:@"close"];
        [button addTarget:self action:@selector(_close) forControlEvents:UIControlEventTouchUpInside];
        button.contentColor = JoyyBlue;
        button.foregroundColor = ClearColor;

        _closeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return _closeButtonItem;
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
    NSURL *url = [NSURL URLWithString:self.post.URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.photoView setImageWithURLRequest:request
                          placeholderImage:self.post.localImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       weakSelf.photoView.image = image;

                                       if (!weakSelf.post.localImage)
                                       {
                                           weakSelf.photoView.alpha = 0;
                                           [UIView animateWithDuration:0.5 animations:^{
                                               weakSelf.photoView.alpha = 1;
                                           }];
                                       }
                                       weakSelf.post.localImage = image;

                                   } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                       NSLog(@"setImageWithURLRequest failed with error = %@", error);
                                   }];

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
    }
}

- (void)_scrollToTableBottom
{
    if (self.commentList.count > 0)
    {
        NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:self.commentList.count-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastIndex atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.commentList.count + 1; // Use 1 dummy cell to cover the background photo with JoyyBlack50 color
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYCommentlineCell *cell =
    (JYCommentlineCell *)[tableView dequeueReusableCellWithIdentifier:kCommentlineCellIdentifier forIndexPath:indexPath];

    if (indexPath.row < self.commentList.count)
    {
        cell.comment = self.commentList[indexPath.row];
    }
    else
    {
        cell.comment = nil;
    }

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.commentList.count)
    {
        return SCREEN_WIDTH;
    }
    return UITableViewAutomaticDimension;
}

#pragma mark - Maintain Table

- (void)_receivedComments:(NSArray *)commentList
{
    if ([commentList count] == 0)
    {
        return;
    }

    for (JYComment *comment in commentList)
    {
        NSNumber *antiCommentId = [comment antiCommentId];
        if (antiCommentId)
        {
            // delete from DB
            JYComment *dummy = [[JYComment alloc] initWithCommentId:antiCommentId];
            [[JYLocalDataManager sharedInstance] deleteObject:dummy ofClass:JYComment.class];
        }
        else
        {
            if ([comment.postId unsignedLongLongValue] == [self.post.postId unsignedLongLongValue] && ![comment isLike])
            {
                [self.commentList addObject:comment];
                [self.post.commentList addObject:comment];
            }
            [[JYLocalDataManager sharedInstance] insertObject:comment ofClass:JYComment.class];
        }
    }

    [self.tableView reloadData];
}

#pragma mark - Overriden Method

// Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
- (void)didPressRightButton:(id)sender
{
    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    [self.textView refreshFirstResponder];

    [self _stopCloseTimer];
    [self _postComment];
    [super didPressRightButton:sender];
}

#pragma mark - Network

- (void)_postComment
{
    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"post/comment/create"];

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:[self _parametersForCreatingComment]
          success:^(NSURLSessionTask *operation, id responseObject) {
              NSLog(@"Comment POST Success responseObject: %@", responseObject);

              NSDictionary *dict = (NSDictionary *)responseObject;
              NSError *error = nil;
              JYComment *comment = (JYComment *)[MTLJSONAdapter modelOfClass:JYComment.class fromJSONDictionary:dict error:&error];
              if (comment)
              {
                  NSArray *commentList = @[comment];
                  [weakSelf _receivedComments:commentList];
              }

              [weakSelf _scrollToTableBottom];
              [weakSelf _networkThreadEnd];
              [weakSelf _closeInSecs:0.6];
          }
          failure:^(NSURLSessionTask *operation, NSError *error) {

              [weakSelf _networkThreadEnd];

              [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                             message:error.localizedDescription
                     backgroundColor:FlatYellow
                           textColor:FlatBlack
                                time:5];
          }
     ];
}

- (void)_fetchNewComments
{
    [self _stopCloseTimer];

    if (self.networkThreadCount > 0)
    {
        return;
    }
    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    NSString *url = [NSString apiURLWithPath:@"post/commentline"];

    JYComment *maxComment = [[JYLocalDataManager sharedInstance] maxIdObjectOfOfClass:JYComment.class];
    uint64_t sinceid = maxComment? [maxComment.commentId unsignedLongLongValue]: 0;
    uint64_t beforeid = LLONG_MAX;
    
    NSDictionary *parameters = @{@"sinceid": @(sinceid), @"beforeid": @(beforeid)};
    NSLog(@"commentViewController post/commentline params: sinceid = %llu, beforeid = %llu", sinceid, beforeid);

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"GET post/commentline success responseObject: %@", responseObject);

             NSMutableArray *commentList = [NSMutableArray new];

             for (NSDictionary *dict in responseObject)
             {
                 NSError *error = nil;
                 JYComment *comment = (JYComment *)[MTLJSONAdapter modelOfClass:JYComment.class fromJSONDictionary:dict error:&error];
                 if (comment)
                 {
                     [commentList addObject:comment];
                 }
             }

             if ([commentList count] > 0)
             {
                 [weakSelf _receivedComments:commentList];
             }

             [weakSelf _scrollToTableBottom];
             [weakSelf _networkThreadEnd];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"GET post/commentline error = %@", error);
             [weakSelf _networkThreadEnd];
         }
     ];
}

- (NSDictionary *)_parametersForCreatingComment
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:@([self.post.postId unsignedLongLongValue]) forKey:@"postid"];
    [parameters setObject:@([self.post.ownerId unsignedLongLongValue]) forKey:@"posterid"];
    [parameters setObject:self.textView.text forKey:@"content"];

    if (self.originalComment)
    {
        [parameters setObject:@([self.originalComment.ownerId unsignedLongLongValue]) forKey:@"replytoid"];
    }

    return parameters;
}

@end
