//
//  JYTimelineViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/25/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <MJRefresh/MJRefresh.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYButton.h"
#import "JYComment.h"
#import "JYCommentViewController.h"
#import "JYCreatePostController.h"
#import "JYDay.h"
#import "JYFriendManager.h"
#import "JYJellyView.h"
#import "JYLocalDataManager.h"
#import "JYNewCommentViewController.h"
#import "JYPhotoCaptionViewController.h"
#import "JYPost.h"
#import "JYRefreshHeader.h"
#import "JYReminderView.h"
#import "JYTimelineCell.h"
#import "JYTimelineViewController.h"
#import "JYUserlineViewController.h"
#import "TGCameraColor.h"
#import "TGCameraViewController.h"
#import "NSDate+Joyy.h"
#import "UIImage+Joyy.h"

@interface JYTimelineViewController () <JYRefreshHeaderDelegate, TGCameraDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) CABasicAnimation *colorPulse;
@property (nonatomic) JYButton *cameraButton;
@property (nonatomic) JYCreatePostController *createPostController;
@property (nonatomic) JYDay *minDay;
@property (nonatomic) JYPost *currentPost;
@property (nonatomic) JYJellyView *jellyView;
@property (nonatomic) JYRefreshHeader *refreshHeader;
@property (nonatomic) JYReminderView *reminderView;
@property (nonatomic) NSInteger networkThreadCount;
@property (nonatomic) NSMutableArray *postList;
@property (nonatomic) NSMutableArray *unreadCommentList;
@property (nonatomic) NSNumber *newestPostId;
@property (nonatomic) UIButton *titleButton;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic, copy) Action pendingAction;
@end

static const NSInteger OFFSET_DAYS = -10;
static const CGFloat kCameraButtonWidth = 50;
static const CGFloat kRefreshHeaderHeight = 54;
static NSString *const kTimelineCellIdentifier = @"timelineCell";

@implementation JYTimelineViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Home", nil);

    self.navigationController.navigationBar.translucent = YES;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    self.navigationItem.titleView = self.titleButton;

    self.networkThreadCount = 0;
    self.createPostController = [JYCreatePostController new];
    self.currentPost = nil;
    self.postList = [NSMutableArray new];
    self.newestPostId = 0;

    [self.view addSubview:self.tableView];
    [self.view addSubview:self.cameraButton];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_apiTokenReady) name:kNotificationAPITokenReady object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_likePost:) name:kNotificationLikePost object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_createComment:) name:kNotificationCreateComment object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_deleteComment:) name:kNotificationDeleteComment object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_deletePost:) name:kNotificationDeletePost object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tapOnUser:) name:kNotificationDidTapOnUser object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tapOnReminderView:) name:kNotificationDidTapReminderView object:nil];

    __weak typeof(self) weakSelf = self;
    [self _fetchLocalTimelineWithAction:^{
        [weakSelf _fetchNewPost];
    }];
}

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.estimatedRowHeight = 455;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        [_tableView registerClass:[JYTimelineCell class] forCellReuseIdentifier:kTimelineCellIdentifier];

        // Setup the pull-down-to-refresh header
        _tableView.mj_header = self.refreshHeader;
        [_tableView addSubview:self.jellyView];

        // Setup the pull-up-to-refresh footer
        MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(_fetchOldPost)];
        footer.refreshingTitleHidden = YES;
        footer.stateLabel.hidden = YES;
        _tableView.mj_footer = footer;
    }
    return _tableView;
}

// Not used
- (UIView *)backgroundView
{
    if (!_backgroundView)
    {
        _backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"timeline_bg"]];

        _backgroundView.frame = self.view.frame;
        UIBlurEffect* blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurView.frame = _backgroundView.frame;
        [_backgroundView addSubview:blurView];
    }
    return _backgroundView;
}

- (JYRefreshHeader *)refreshHeader
{
    if (!_refreshHeader)
    {
        _refreshHeader = [JYRefreshHeader headerWithRefreshingTarget:self refreshingAction:@selector(_fetchNewPost)];
        _refreshHeader.delegate = self;
        _refreshHeader.jellyView = self.jellyView;
    }
    return _refreshHeader;
}

- (JYJellyView *)jellyView
{
    if (!_jellyView)
    {
        _jellyView = [[JYJellyView alloc] initWithFrame:CGRectMake(0, -kRefreshHeaderHeight, SCREEN_WIDTH, kRefreshHeaderHeight)];
    }
    return _jellyView;
}

#pragma mark - JYRefreshHeaderDelegate methods

- (void)refreshHeader:(JYRefreshHeader *)header willResetJellyView:(JYJellyView *)jellyView
{
    [self.jellyView removeFromSuperview];
    self.jellyView = nil;
    [self.tableView addSubview:self.jellyView];
    header.jellyView = self.jellyView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.cameraButton.imageLayer.layer removeAllAnimations];
    [self.cameraButton.imageLayer.layer addAnimation:self.colorPulse forKey:@"ColorPulse"];
    [self _refreshCurrentCell];
}

- (void)_refreshCurrentCell
{
    if (!self.currentPost)
    {
        [self.tableView reloadData];
        return;
    }

    NSInteger selectedRow = [self.postList indexOfObject:self.currentPost];
    self.currentPost = nil;
    if (selectedRow == NSNotFound)
    {
        return;
    }

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectedRow inSection:0];
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_apiTokenReady
{
    if (self.pendingAction)
    {
        self.pendingAction();
    }
}

- (JYReminderView *)reminderView
{
    if (!_reminderView)
    {
        _reminderView = [JYReminderView new];
    }
    return _reminderView;
}

- (UIButton *)titleButton
{
    if (!_titleButton)
    {
        NSString *title = NSLocalizedString(@"Home", nil);
        _titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _titleButton.frame = CGRectMake(0, 0, 70, 44);
        _titleButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [_titleButton setTitle:title forState:UIControlStateNormal];
        [_titleButton setTitleColor:JoyyBlack forState:UIControlStateNormal];
        [_titleButton addTarget:self action:@selector(_scrollToTop) forControlEvents:UIControlEventTouchUpInside];
    }
    return _titleButton;
}

- (void)_scrollToTop
{
    if (self.postList.count == 0)
    {
        return;
    }

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (JYButton *)cameraButton
{
    if (!_cameraButton)
    {
        CGRect frame = CGRectMake(0, 0, kCameraButtonWidth, kCameraButtonWidth);
        _cameraButton = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
        _cameraButton.centerX = self.view.centerX;
        _cameraButton.centerY = SCREEN_HEIGHT - self.tabBarController.tabBar.height;

        _cameraButton.imageView.image = [UIImage imageNamed:@"CameraShot"];
        _cameraButton.contentColor = JoyyWhite50;
        _cameraButton.contentAnimateToColor = JoyyWhite;
        _cameraButton.foregroundColor = ClearColor;
        [_cameraButton addTarget:self action:@selector(_showCamera) forControlEvents:UIControlEventTouchDown];
    }
    return _cameraButton;
}

- (CABasicAnimation *)colorPulse
{
    if (!_colorPulse)
    {
        _colorPulse = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
        _colorPulse.duration = 5.0;
        _colorPulse.repeatCount = INFINITY;
        _colorPulse.autoreverses = YES;
        _colorPulse.fromValue = (__bridge id)([JoyyWhite80 CGColor]);
        _colorPulse.toValue = (__bridge id)([JoyyGray CGColor]);
    }
    return _colorPulse;
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
        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer endRefreshing];
    }
}

- (void)_likePost:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (info)
    {
        id value = [info objectForKey:@"post"];
        if (value != [NSNull null])
        {
            JYPost *post = (JYPost *)value;
            self.currentPost = post;
            [self _like:post];
        }
    }
}

- (void)_createComment:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (info)
    {
        id postObj = [info objectForKey:@"post"];
        id commentObj = [info objectForKey:@"comment"];
        if (postObj != [NSNull null])
        {
            JYPost *post = (JYPost *)postObj;
            self.currentPost = post;
            JYComment *comment = nil;

            if (commentObj != [NSNull null])
            {
                comment = (JYComment *)commentObj;
            }
            [self _showCommentCreateViewForPost:post replyToComment:comment];
        }
    }
}

- (void)_deletePost:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (info)
    {
        id post = [info objectForKey:@"post"];
        if (post != [NSNull null])
        {
            [self _showOptionsToDeletePost:post];
        }
    }
}

- (void)_showOptionsToDeletePost:(JYPost *)post
{
    NSString *cancel = NSLocalizedString(@"Cancel", nil);
    NSString *delete = NSLocalizedString(@"Delete", nil);

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:delete style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action) {
                                                [weakSelf _doDeletePost:post];
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)_deleteComment:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (info)
    {
        id comment = [info objectForKey:@"comment"];
        id post = [info objectForKey:@"post"];
        if (comment != [NSNull null] && post != [NSNull null])
        {
            [self _showOptionsToDeleteComment:comment ofPost:post];
        }
    }
}

- (void)_showOptionsToDeleteComment:(JYComment *)comment ofPost:(JYPost *)post
{
    NSString *cancel = NSLocalizedString(@"Cancel", nil);
    NSString *delete = NSLocalizedString(@"Delete", nil);

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:delete style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action) {
                                                [weakSelf _doDeleteComment:comment ofPost:post];
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)_tapOnUser:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (!info)
    {
        return;
    }

    id value = [info objectForKey:@"userid"];
    if (value == [NSNull null])
    {
        return;
    }

    NSNumber *userid = (NSNumber *)value;
    JYUser *user = [[JYFriendManager sharedInstance] friendWithId:userid];
    JYUserlineViewController *viewController = [[JYUserlineViewController alloc] initWithUser:user];

    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)_tapOnReminderView:(NSNotification *)notification
{
    [self _showNewComments];
}

- (void)_showNewComments
{
//    self.tableView.tableHeaderView = nil;

    JYNewCommentViewController *viewController = [[JYNewCommentViewController alloc] init];
    viewController.commentList = [NSArray arrayWithArray:self.unreadCommentList];
    self.unreadCommentList = nil;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void) _showCommentCreateViewForPost:(JYPost *)post replyToComment:(JYComment *)comment
{
    JYCommentViewController *viewController = [[JYCommentViewController alloc] initWithPost:post comment:comment];

    CATransition *transition = [CATransition animation];
    transition.duration = 0.05;
    transition.type = kCATransitionFade;
    transition.subtype = kCATransitionFromBottom;

    [self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
    [self.navigationController pushViewController:viewController animated:NO];
}

- (void)_showCamera
{
    JYPhotoCaptionViewController *captionVC = [[JYPhotoCaptionViewController alloc] initWithDelegate:self];

    [TGCameraColor setTintColor:JoyyBlue];
    TGCameraNavigationController *camera = [TGCameraNavigationController cameraWithDelegate:self captionViewController:captionVC];

    [self presentViewController:camera animated:NO completion:nil];
}

#pragma mark - TGCameraDelegate Methods

- (void)cameraDidCancel
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)cameraDidTakePhoto:(UIImage *)photo fromAlbum:(BOOL)fromAlbum withCaption:(NSString *)caption
{
    // Default caption
    if (caption.length == 0 || [caption isInvisible])
    {
        caption = nil;
    }

    // Handling and upload the photo
    UIImage *image = [UIImage imageWithImage:photo scaledToSize:CGSizeMake(kPhotoWidth, kPhotoWidth)];

    [self _fetchNewPost]; // make sure timeline is refreshed before create new post
    [self dismissViewControllerAnimated:YES completion:nil];

    __weak typeof(self) weakSelf = self;
    [self _networkThreadBegin];
    [self.createPostController createPostWithMedia:image caption:caption success:^(JYPost *post) {

        post.localImage = image;
        [weakSelf _createdNewPost:post];
        [weakSelf _networkThreadEnd];
    } failure:^(NSError *error) {

        [weakSelf _networkThreadEnd];
        [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                       message:error.localizedDescription
               backgroundColor:FlatYellow
                     textColor:FlatBlack
                          time:5];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = self.postList.count;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYTimelineCell *cell =
    (JYTimelineCell *)[tableView dequeueReusableCellWithIdentifier:kTimelineCellIdentifier forIndexPath:indexPath];

    JYPost *post = self.postList[indexPath.row];
    cell.post = post;

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section != 0)
    {
        return 0;
    }

    if (self.unreadCommentList)
    {
        return 40;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section != 0)
    {
        return nil;
    }

    if (self.unreadCommentList)
    {
        return self.reminderView;
    }
    return nil;
}

#pragma mark - Maintain table

- (void)_createdNewPost:(JYPost *)post
{
    if (!post)
    {
        return;
    }
    
    [[JYLocalDataManager sharedInstance] insertObjects:@[post] ofClass:JYPost.class];

    self.newestPostId = post.postId;

    [self.postList insertObject:post atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView endUpdates];
}

- (void)_receivedNewPosts:(NSMutableArray *)postList
{
    if ([postList count] == 0) // no new post, continue to fetch new comments
    {
       NSNumber *sinceId = [JYLocalDataManager sharedInstance].maxCommentIdInDB;
        if (sinceId > 0)
        {
            [self _fetchCommentsSinceId:[sinceId unsignedLongLongValue] beforeId:LLONG_MAX];
        }
        return;
    }

    JYPost *newestPost = postList[0];
    self.newestPostId = newestPost.postId;

    NSNumber *sinceId = ((JYPost *)[postList lastObject]).postId;
    [self _fetchCommentsSinceId:[sinceId unsignedLongLongValue] beforeId:LLONG_MAX];

    NSMutableArray *purifiedPostList = [self _purifiedPostListFromList:postList];
    [[JYLocalDataManager sharedInstance] insertObjects:purifiedPostList ofClass:JYPost.class];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [purifiedPostList addObjectsFromArray:self.postList];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.postList = purifiedPostList;
            [self.tableView reloadData];
        });
    });
}

- (void)_receivedOldPosts:(NSMutableArray *)postList
{
    if ([postList count] == 0) // no more old post, do nothing
    {
        return;
    }

    uint64_t minId = [((JYPost *)[postList lastObject]).postId unsignedLongLongValue];
    uint64_t maxId = LLONG_MAX;
    if ([self.postList count] > 0)
    {
        JYPost *post = [self.postList lastObject];
        maxId = [post.postId unsignedLongLongValue]; // the comment id larger than maxId should already be fetched
    }

    if (minId < maxId)
    {
        [self _fetchCommentsSinceId:minId beforeId:maxId];
    }

    NSArray *purifiedPostList = [self _purifiedPostListFromList:postList];
    [[JYLocalDataManager sharedInstance] insertObjects:purifiedPostList ofClass:JYPost.class];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _refreshCommentsForPostList:purifiedPostList];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.postList addObjectsFromArray:purifiedPostList];
            [self.tableView reloadData];
            [self.tableView.mj_footer endRefreshing];
        });
    });
}

- (NSMutableArray *)_purifiedPostListFromList:(NSArray *)list
{
    NSMutableSet *antiPostIdSet = [NSMutableSet new];
    for (JYPost *post in list)
    {
        NSNumber *antiPostId = [post antiPostId];
        if (antiPostId)
        {
            [antiPostIdSet addObject:antiPostId];
            JYPost *dummy = [[JYPost alloc] initWithPostId:antiPostId];
            [[JYLocalDataManager sharedInstance] deleteObject:dummy ofClass:JYPost.class];
        }
    }

    NSMutableArray *postList = [NSMutableArray new];
    for (JYPost *post in list)
    {
        NSNumber *antiPostId = [post antiPostId];
        if (!antiPostId && ![antiPostIdSet containsObject:post.postId])
        {
            [postList addObject:post];
        }
    }
    return postList;
}

- (void)_receivedNewComments:(NSArray *)list
{
    NSMutableSet *antiCommentIdSet = [NSMutableSet new];
    for (JYComment *comment in list)
    {
        NSNumber *antiCommentId = [comment antiCommentId];
        if (antiCommentId)
        {
            [antiCommentIdSet addObject:antiCommentId];
        }
    }

    self.unreadCommentList = [NSMutableArray new];
    for (JYComment *comment in list)
    {
        NSNumber *antiCommentId = [comment antiCommentId];
        if (!antiCommentId && ![antiCommentIdSet containsObject:comment.commentId])
        {
            [self.unreadCommentList addObject:comment];
        }
    }

    uint64_t count = [self.unreadCommentList count];
    if (count > 0)
    {
        NSString *comments = NSLocalizedString(@"new comments", nil);
        self.reminderView.text = [NSString stringWithFormat:@"%llu %@", count, comments];
    }
}

- (void)_like:(JYPost *)post
{
    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"post/comment/create"];
    NSDictionary *parameters = @{
                                   @"postid": @([post.postId unsignedLongLongValue]),
                                   @"posterid": @([post.ownerId unsignedLongLongValue]),
                                   @"replytoid": @(0),
                                   @"content": kLikeText
                               };

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:parameters
          success:^(NSURLSessionTask *operation, id responseObject) {
              NSLog(@"like post like success responseObject: %@", responseObject);
              
              NSDictionary *dict = (NSDictionary *)responseObject;
              NSError *error = nil;
              JYComment *comment = (JYComment *)[MTLJSONAdapter modelOfClass:JYComment.class fromJSONDictionary:dict error:&error];
              if (comment)
              {
                  [[JYLocalDataManager sharedInstance] insertObject:comment ofClass:JYComment.class];
                  [post.commentList addObject:comment];
              }

              [weakSelf _refreshCurrentCell];
              [weakSelf _networkThreadEnd];
          }
          failure:^(NSURLSessionTask *operation, NSError *error) {
              NSLog(@"like post like failed with error: %@", error);
              [weakSelf _networkThreadEnd];
          }
     ];
}

- (void)_refreshCommentsForPostList:(NSArray *)postList
{
    if ([postList count] == 0)
    {
        return;
    }

    for (JYPost *post in postList)
    {
        post.commentList = [[JYLocalDataManager sharedInstance] selectCommentsOfPostId:post.postId];
    }
}

- (void)_fetchLocalTimelineWithAction:(Action)action
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDate *date = [[NSDate date] dateByAddingTimeInterval:60 * 60 * 24 * OFFSET_DAYS];
        NSNumber *minId = [date minId];
        NSNumber *maxId = [[NSDate date] currentId];

        self.postList = [[JYLocalDataManager sharedInstance] selectPostsSinceId:minId beforeId:maxId];

        if ([self.postList count] == 0)
        {
            self.newestPostId = 0;
            self.minDay = [[JYDay alloc] initWithDate:[NSDate date]];
        }
        else
        {
            JYPost *newestPost = self.postList[0];
            self.newestPostId = newestPost.postId;

            JYPost *oldestPost = [self.postList lastObject];
            NSDate *date = [NSDate dateOfId:oldestPost.postId];
            self.minDay = [[JYDay alloc] initWithDate:date];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self _refreshCommentsForPostList:self.postList];
            [self.tableView reloadData];

            if (action)
            {
                action();
            }
        });
    });
}

- (void)_fetchNewPost
{
    if ([JYCredential current].tokenValidInSeconds <= 0)
    {
        __weak typeof(self) weakSelf = self;
        self.pendingAction = ^{
            [weakSelf _fetchNewPost];
        };
        return;
    }
    self.pendingAction = nil;

    JYDay *today = [[JYDay alloc] initWithDate:[NSDate date]];
    [self _fetchRemoteTimelineOfDay:today.value sinceId:[self.newestPostId unsignedLongLongValue]];
}

- (void)_fetchOldPost
{
    if ([JYCredential current].tokenValidInSeconds <= 0)
    {
        __weak typeof(self) weakSelf = self;
        self.pendingAction = ^{
            [weakSelf _fetchOldPost];
        };
        return;
    }
    self.pendingAction = nil;

    self.minDay = [self.minDay prev];
    [self _fetchTimelineOfDay:self.minDay];
}

- (void)_fetchTimelineOfDay:(JYDay *)jyDay
{
    // fetch local timeline first, if none, then fetch remote timeline
    NSNumber *minId = [jyDay.date minId];

    JYDay *nextDay = [jyDay next];
    NSNumber *maxId = [nextDay.date minId];

    NSArray *postList = [[JYLocalDataManager sharedInstance] selectPostsSinceId:minId beforeId:maxId];
    if ([postList count] == 0)
    {
        [self _fetchRemoteTimelineOfDay:jyDay.value sinceId:0];
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self _refreshCommentsForPostList:postList];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.postList addObjectsFromArray:postList];
                [self.tableView reloadData];
                [self.tableView.mj_footer endRefreshing];
            });
        });
    }
}

- (void)_fetchRemoteTimelineOfDay:(uint64_t)day sinceId:(uint64_t)minId
{
    if (self.networkThreadCount > 0)
    {
        return;
    }

    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    NSString *url = [NSString apiURLWithPath:@"post/timeline"];
    NSDictionary *parameters = @{@"day": @(day), @"sinceid": @(minId)};

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"post/timeline fetch success responseObject: %@", responseObject);

             // the post json is in ASC order, so iterate reversely
             NSMutableArray *postList = [NSMutableArray new];
             for (NSDictionary *dict in [responseObject reverseObjectEnumerator])
             {
                 NSError *error = nil;
                 JYPost *post = (JYPost *)[MTLJSONAdapter modelOfClass:JYPost.class fromJSONDictionary:dict error:&error];
                 if (post)
                 {
                     [postList addObject:post];
                 }
             }

             if (minId > 0) // fetch new request
             {
                 [weakSelf _receivedNewPosts:postList];
             }
             else
             {
                 [weakSelf _receivedOldPosts:postList];
             }
             [weakSelf _networkThreadEnd];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"Error: post/timeline fetch failed with error: %@", error);
             [weakSelf _networkThreadEnd];
         }
     ];
}

- (void)_fetchCommentsSinceId:(uint64_t)minId beforeId:(uint64_t)maxId
{
    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"post/commentline"];
    NSDictionary *parameters = @{@"sinceid": @(minId), @"beforeid": @(maxId)};

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
                 [[JYLocalDataManager sharedInstance] receivedCommentList:commentList];
                 [weakSelf _refreshCommentsForPostList:weakSelf.postList];
                 [weakSelf _receivedNewComments:commentList];
                 [weakSelf.tableView reloadData];
             }
             [weakSelf _networkThreadEnd];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"GET post/commentline error = %@", error);
             [weakSelf _networkThreadEnd];
         }
     ];
}

- (void)_doDeletePost:(JYPost *)post
{
    if (!post)
    {
        return;
    }

    if (self.networkThreadCount > 0)
    {
        return;
    }

    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"post/delete"];
    NSDictionary *parameters = @{@"postid": @([post.postId unsignedLongLongValue])};

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:parameters
          success:^(NSURLSessionTask *operation, id responseObject) {
              NSLog(@"delete post success");

              [[JYLocalDataManager sharedInstance] deleteObject:post ofClass:JYPost.class];

              [weakSelf.postList removeObject:post];
              [weakSelf.tableView reloadData];
              [weakSelf _networkThreadEnd];
          }
          failure:^(NSURLSessionTask *operation, NSError *error) {
              NSLog(@"delete post failed with error: %@", error);
              [weakSelf _networkThreadEnd];
          }
     ];
}

- (void)_doDeleteComment:(JYComment *)comment ofPost:(JYPost *)post
{
    if (!comment || !post)
    {
        return;
    }

    if (self.networkThreadCount > 0)
    {
        return;
    }

    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"post/comment/delete"];
    NSDictionary *parameters = [self _parametersOfDeleteComment:comment ofPost:post];

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:parameters
          success:^(NSURLSessionTask *operation, id responseObject) {
              NSLog(@"delete comment success");

              [[JYLocalDataManager sharedInstance] deleteObject:comment ofClass:JYComment.class];

              [weakSelf _removeCommentWithId:comment.commentId fromList:post.commentList];
              weakSelf.currentPost = post;
              [weakSelf _refreshCurrentCell];
              [weakSelf _networkThreadEnd];
          }
          failure:^(NSURLSessionTask *operation, NSError *error) {
              NSLog(@"delete comment like failed with error: %@", error);
              [weakSelf _networkThreadEnd];
          }
     ];
}

- (NSDictionary *)_parametersOfDeleteComment:(JYComment *)comment ofPost:(JYPost *)post
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    [parameters setObject:@([comment.commentId unsignedLongLongValue]) forKey:@"commentid"];
    [parameters setObject:@([post.postId unsignedLongLongValue]) forKey:@"postid"];
    [parameters setObject:@([post.ownerId unsignedLongLongValue]) forKey:@"posterid"];


    uint64_t replyToId = [comment.replyToId unsignedLongLongValue];
    if (replyToId > 0)
    {
        [parameters setObject:@(replyToId) forKey:@"replytoid"];
    }

    return parameters;
}

- (void)_removeCommentWithId:(NSNumber *)commentId fromList:(NSMutableArray *)list
{
    NSUInteger count = [list count];
    uint64_t value = [commentId unsignedLongLongValue];
    for (NSUInteger index = 0; index < count; index++)
    {
        JYComment *c = list[index];
        if (value == [c.commentId unsignedLongLongValue])
        {
            [list removeObjectAtIndex:index];
            break;
        }
    }
}

@end
