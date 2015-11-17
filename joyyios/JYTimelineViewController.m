//
//  JYMasqueradeViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/25/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <AWSS3/AWSS3.h>
#import <MJRefresh/MJRefresh.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYButton.h"
#import "JYPhotoCaptionViewController.h"
#import "JYComment.h"
#import "JYCommentViewController.h"
#import "JYFilename.h"
#import "JYLocalDataManager.h"
#import "JYTimelineViewController.h"
#import "JYPost.h"
#import "JYPostViewCell.h"
#import "TGCameraColor.h"
#import "TGCameraViewController.h"
#import "NSDate+Joyy.h"
#import "UIImage+Joyy.h"

@interface JYTimelineViewController () <TGCameraDelegate, UITableViewDataSource, UITableViewDelegate>
@property(nonatomic) CABasicAnimation *colorPulse;
@property(nonatomic) JYButton *cameraButton;
@property(nonatomic) JYPost *currentPost;
@property(nonatomic) NSInteger networkThreadCount;
@property(nonatomic) NSMutableArray *postList;
@property(nonatomic) NSDate *firstDate;
@property(nonatomic) UIButton *titleButton;
@property(nonatomic) UIColor *originalTabBarTintColor;
@property(nonatomic) UITableView *tableView;
@property(nonatomic) uint64_t newestPostId;
@end

typedef void(^VoidHandler)();

static const NSInteger OFFSET_DAYS = -3;
static const CGFloat kCameraButtonWidth = 50;
static NSString *const kPostCellIdentifier = @"postCell";

@implementation JYTimelineViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Home", nil);
    // Do not use UIBarStyleBlack in the next line, because it will make the status bar text white
    // self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

    // Setup the navigationBar appearence and function
    self.navigationController.navigationBar.barTintColor = JoyyBlack;
    self.navigationController.navigationBar.translucent = YES;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    self.navigationItem.titleView = self.titleButton;

    self.networkThreadCount = 0;
    self.currentPost = nil;
    self.postList = [NSMutableArray new];
    self.newestPostId = 0;

    [self.view addSubview:self.tableView];
    [self.view addSubview:self.cameraButton];

    __weak typeof(self) weakSelf = self;
    [self _fetchPostsFromDBWithCompleteHandler:^{
        [weakSelf _fetchNewPost];
    }];

    self.originalTabBarTintColor = self.tabBarController.tabBar.barTintColor;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_like:) name:kNotificationWillLikePost object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_comment:) name:kNotificationWillCommentPost object:nil];
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
        [_titleButton setTitleColor:JoyyGray forState:UIControlStateNormal];
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.barTintColor = JoyyBlack;

    [self.cameraButton.imageLayer.layer removeAllAnimations];
    [self.cameraButton.imageLayer.layer addAnimation:self.colorPulse forKey:@"ColorPulse"];
    [self _reloadCurrentCell];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.tabBarController.tabBar.barTintColor = self.originalTabBarTintColor;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = JoyyBlack;
        _tableView.separatorColor = ClearColor;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        [_tableView registerClass:[JYPostViewCell class] forCellReuseIdentifier:kPostCellIdentifier];

        // Setup the pull-down-to-refresh header
        MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(_fetchNewPost)];
        header.lastUpdatedTimeLabel.hidden = YES;
        header.stateLabel.hidden = YES;
        _tableView.mj_header = header;

        // Setup the pull-up-to-refresh footer
        MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(_fetchOldPost)];
        footer.refreshingTitleHidden = YES;
        footer.stateLabel.hidden = YES;
        _tableView.mj_footer = footer;
    }
    return _tableView;
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

- (void)_like:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (info)
    {
        id value = [info objectForKey:@"post"];
        if (value != [NSNull null])
        {
            JYPost *post = (JYPost *)value;
            [self _likePost:post];
        }
    }
}

- (void)_comment:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (info)
    {
        id postObj = [info objectForKey:@"post"];
        id editObj = [info objectForKey:@"edit"];
        if (postObj != [NSNull null] && editObj != [NSNull null])
        {
            JYPost *post = (JYPost *)postObj;
            self.currentPost = post;
            BOOL edit = [editObj boolValue];
            [self _presentCommentViewForPost:post showKeyBoard:edit];
        }
    }
}

- (void)_reloadCurrentCell
{
    if (!self.currentPost)
    {
        return;
    }

    NSInteger selectedRow = [self.postList indexOfObject:self.currentPost];
    self.currentPost = nil;
    if (selectedRow == NSNotFound)
    {
        return;
    }

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectedRow inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) _presentCommentViewForPost:(JYPost *)post showKeyBoard:(BOOL)edit
{
    JYCommentViewController *viewController = [[JYCommentViewController alloc] initWithPost:post withKeyboard:edit];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)_showCamera
{
    JYPhotoCaptionViewController *captionVC = [[JYPhotoCaptionViewController alloc] initWithDelegate:self];

    [TGCameraColor setTintColor:JoyyBlue];
    TGCameraNavigationController *camera = [TGCameraNavigationController cameraWithCaptionViewController:captionVC];
    camera.title = self.title;

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
        caption = kDummyCaptionText;
    }

    // Handling and upload the photo
    UIImage *image = [UIImage imageWithImage:photo scaledToSize:CGSizeMake(kPhotoWidth, kPhotoWidth)];
    NSData *imageData = UIImageJPEGRepresentation(image, kPhotoQuality);

    [self _createPostWithMediaData:imageData contentType:kContentTypeJPG caption:caption];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.postList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYPostViewCell *cell =
    (JYPostViewCell *)[tableView dequeueReusableCellWithIdentifier:kPostCellIdentifier forIndexPath:indexPath];

    JYPost *post = self.postList[indexPath.row];
    cell.post = post;

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYPost *post = self.postList[indexPath.row];
    return [JYPostViewCell heightForPost:post];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Maintain table

- (void)_receivedNewPosts:(NSMutableArray *)postList
{
    if ([postList count] == 0) // no new post, continue to fetch new comments
    {
        uint64_t sinceId = [JYLocalDataManager sharedInstance].maxCommentIdInDB;
        if (sinceId > 0)
        {
            [self _fetchCommentsSinceId:sinceId beforeId:LLONG_MAX];
        }
        return;
    }

    JYPost *newestPost = self.postList[0];
    self.newestPostId = newestPost.postId;

    uint64_t sinceId = ((JYPost *)[postList lastObject]).postId;
    [self _fetchCommentsSinceId:sinceId beforeId:LLONG_MAX];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [postList addObjectsFromArray:self.postList];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.postList = postList;
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

    uint64_t sinceId = ((JYPost *)[postList lastObject]).postId;
    uint64_t beforeId = [JYLocalDataManager sharedInstance].minCommentIdInDB;
    if (sinceId < beforeId)
    {
        [self _fetchCommentsSinceId:sinceId beforeId:beforeId];
    }

    [self.postList addObjectsFromArray:postList];
    [self.tableView reloadData];
}

#pragma mark - AWS S3

- (void)_createPostWithMediaData:(NSData *)data contentType:(NSString *)contentType caption:(NSString *)caption
{
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"masquerade"]];
    [data writeToURL:fileURL atomically:YES];

    NSString *s3filename = [[JYFilename sharedInstance] randomFilenameWithHttpContentType:contentType];

    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    if (!transferManager)
    {
        NSLog(@"Error: no S3 transferManager");
        return;
    }

    AWSS3TransferManagerUploadRequest *request = [AWSS3TransferManagerUploadRequest new];
    request.bucket = [JYFilename sharedInstance].postBucketName;
    request.key = s3filename;
    request.body = fileURL;
    request.contentType = contentType;

    __weak typeof(self) weakSelf = self;
    [[transferManager upload:request] continueWithBlock:^id(AWSTask *task) {
        if (task.error)
        {
            if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain])
            {
                switch (task.error.code)
                {
                    case AWSS3TransferManagerErrorCancelled:
                    case AWSS3TransferManagerErrorPaused:
                        break;
                    default:
                        NSLog(@"Error: AWSS3TransferManager upload error = %@", task.error);
                        break;
                }
            }
            else
            {
                // Unknown error.
                NSLog(@"Error: AWSS3TransferManager upload error = %@", task.error);
            }
        }
        if (task.result)
        {
            AWSS3TransferManagerUploadOutput *uploadOutput = task.result;
            NSLog(@"Success: AWSS3TransferManager upload task.result = %@", uploadOutput);
            [weakSelf _createPostRecordWithFilename:s3filename caption:caption];
        }
        return nil;
    }];
}

#pragma mark - Network

- (void)_createPostRecordWithFilename:(NSString *)filename caption:(NSString *)caption
{
    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"post"];
    NSMutableDictionary *parameters = [self _parametersForPostWithFilename:filename caption:caption];

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:parameters
          success:^(NSURLSessionTask *operation, id responseObject) {

        NSLog(@"Success: createPostRecord response = %@", responseObject);
//        JYPost *post = [JYPost postWithDictionary:responseObject];
//        [weakSelf _updateTableWithPostList:@[post] old:NO];
        [weakSelf _networkThreadEnd];

    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Failure: createPostRecord error = %@", error);
        [weakSelf _networkThreadEnd];

        [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                       message:error.localizedDescription
               backgroundColor:FlatYellow
                     textColor:FlatBlack
                          time:5];
    }];
}

- (NSMutableDictionary *)_parametersForPostWithFilename:(NSString *)filename caption:(NSString *)caption
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:filename forKey:@"filename"];
    [parameters setObject:caption forKey:@"caption"];

    return parameters;
}

- (void)_likePost:(JYPost *)post
{
    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"post/like"];
    NSDictionary *parameters = @{@"id": @(post.postId)};

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:parameters
          success:^(NSURLSessionTask *operation, id responseObject) {
              //             NSLog(@"post/like POST success responseObject: %@", responseObject);

//              NSDictionary *dict = (NSDictionary *)responseObject;
//              post.likeCount = [[dict objectForKey:@"likes"] unsignedIntegerValue];
              post.isLiked = YES;
              [weakSelf _networkThreadEnd];
          }
          failure:^(NSURLSessionTask *operation, NSError *error) {
              [weakSelf _networkThreadEnd];
          }
     ];
}

- (void)_refreshComments
{
    if ([self.postList count] == 0)
    {
        return;
    }

    for (JYPost *post in self.postList)
    {
        post.commentList = [[JYLocalDataManager sharedInstance] selectCommentsOfPostId:post.postId];
    }

    [self.tableView reloadData];
}

- (void)_fetchPostsFromDBWithCompleteHandler:(VoidHandler)handler
{
    uint64_t minId = [NSDate minIdWithOffsetInDays:OFFSET_DAYS];
    uint64_t maxId = [NSDate idOfNow];

    self.postList = [[JYLocalDataManager sharedInstance] selectPostsSinceId:minId beforeId:maxId];
    [self _refreshComments];

    if ([self.postList count] > 0)
    {
        JYPost *newestPost = self.postList[0];
        self.newestPostId = newestPost.postId;

        JYPost *oldestPost = [self.postList lastObject];
        self.firstDate = [NSDate dateOfId:oldestPost.postId];
    }

    if (handler)
    {
        handler();
    }
}

- (void)_fetchNewPost
{
    uint64_t day = [[NSDate date] joyyDay];
    [self _fetchTimelineOfDay:day sinceId:self.newestPostId];
}

- (void)_fetchOldPost
{
    self.firstDate = [self.firstDate dateByAddingTimeInterval:60 * 60 * 24 * (-1)];
    uint64_t day = [self.firstDate joyyDay];
    [self _fetchTimelineOfDay:day sinceId:0];
}

- (void)_fetchTimelineOfDay:(uint64_t)day sinceId:(uint64_t)minId
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
             [weakSelf _networkThreadEnd];
         }
     ];
}

- (void)_fetchCommentsSinceId:(uint64_t)minId beforeId:(uint64_t)maxId
{
    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];

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
             [[JYLocalDataManager sharedInstance] saveObjects:commentList ofClass:JYComment.class];
             [weakSelf _refreshComments];
             [weakSelf _networkThreadEnd];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"GET post/commentline error = %@", error);
             [weakSelf _networkThreadEnd];
         }
     ];
}

@end
