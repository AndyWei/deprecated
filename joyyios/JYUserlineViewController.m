//
//  JYUserlineViewController.m
//  joyyios
//
//  Created by Ping Yang on 12/8/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <AWSS3/AWSS3.h>
#import <MJRefresh/MJRefresh.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYMonth.h"
#import "JYButton.h"
#import "JYCardView.h"
#import "JYComment.h"
#import "JYCommentViewController.h"
#import "JYFilename.h"
#import "JYLocalDataManager.h"
#import "JYPhotoCaptionViewController.h"
#import "JYPost.h"
#import "JYUserlineCell.h"
#import "JYUserlineViewController.h"
#import "TGCameraColor.h"
#import "TGCameraViewController.h"
#import "UIImage+Joyy.h"

@interface JYUserlineViewController () <TGCameraDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) JYMonth *month;
@property (nonatomic) JYUser *user;
@property (nonatomic) JYUserlineCell *sizingCell;
@property (nonatomic) JYCardView *cardView;
@property (nonatomic) NSInteger networkThreadCount;
@property (nonatomic) NSLayoutConstraint *cardViewHeightConstraint;
@property (nonatomic) NSMutableArray *postList;
@property (nonatomic) UITableView *tableView;
@property (nonatomic, copy) Action pendingAction;
@end

static NSString *const kUserlineCellIdentifier = @"userlineCell";
static CGFloat kCardViewDefaultHeight = 150;

@implementation JYUserlineViewController

- (instancetype)initWithUser:(JYUser *)user
{
    if (self = [super init])
    {
        self.user = user;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.user.username;

    self.navigationController.navigationBar.translucent = YES;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];

    self.networkThreadCount = 0;
    self.postList = [NSMutableArray new];
    self.month = [[JYMonth alloc] initWithDate:[NSDate date]];

    [self.view addSubview:self.tableView];
    [self.view addSubview:self.cardView];

    NSDictionary *views = @{ @"cardView": self.cardView };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[cardView]-(>=100@500)-|" options:0 metrics:nil views:views]];
    self.cardViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.cardView
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:0.0f
                                                                  constant:kCardViewDefaultHeight];
    [self.view addConstraint:self.cardViewHeightConstraint];
    [self _updateCardViewContent];


    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_apiTokenReady) name:kNotificationAPITokenReady object:nil];

    [self _fetchUserline];
}

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 415;
        [_tableView registerClass:[JYUserlineCell class] forCellReuseIdentifier:kUserlineCellIdentifier];

        _tableView.contentInset = UIEdgeInsetsMake(kCardViewDefaultHeight, 0, 0, 0);

        // Setup the pull-up-to-refresh footer
        MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(_fetchUserline)];
        footer.refreshingTitleHidden = YES;
        footer.stateLabel.hidden = YES;
        _tableView.mj_footer = footer;
    }
    return _tableView;
}

- (JYCardView *)cardView
{
    if (!_cardView)
    {
        _cardView = [[JYCardView alloc] init];
//        [_cardView addBlur];
    }
    return _cardView;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView
{
    CGFloat offset = (-1) * _tableView.contentOffset.y;

    self.cardViewHeightConstraint.constant = fmax(offset, kCardViewDefaultHeight);

    if (offset < 120)
    {
        [UIView animateWithDuration:0.3 animations:^{
             self.cardView.alpha = 0;
        }];
    }
    else
    {
        self.cardView.alpha = 1.0;
    }

    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
}

- (void)_updateCardViewContent
{
    self.cardView.titleLabel.text = self.user.username;

    NSURL *url = [NSURL URLWithString:self.user.avatarURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.cardView.avatarView setImageWithURLRequest:request
                                          placeholderImage:nil
                                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                       weakSelf.cardView.avatarView.image = image;
                                                       weakSelf.cardView.coverView.image = image;
                                                   } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                       NSLog(@"_updateCardView setImageWithURLRequest failed with error = %@", error);
                                                   }];

}

- (void)_apiTokenReady
{
    if (self.pendingAction)
    {
        self.pendingAction();
    }
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
        [self.tableView.mj_footer endRefreshing];
    }
}

- (void)_showCamera
{
    JYPhotoCaptionViewController *captionVC = [[JYPhotoCaptionViewController alloc] initWithDelegate:self];

    [TGCameraColor setTintColor:JoyyBlue];
    TGCameraNavigationController *camera = [TGCameraNavigationController cameraWithDelegate:self captionViewController:captionVC];
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
    // Handling and upload the photo
//    UIImage *image = [UIImage imageWithImage:photo scaledToSize:CGSizeMake(kPhotoWidth, kPhotoWidth)];
//
////    [self _createPostWithImage:image contentType:kContentTypeJPG caption:caption];
////    [self dismissViewControllerAnimated:YES completion:nil];
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
    JYUserlineCell *cell =
    (JYUserlineCell *)[tableView dequeueReusableCellWithIdentifier:kUserlineCellIdentifier forIndexPath:indexPath];

    JYPost *post = self.postList[indexPath.row];
    cell.post = post;

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

#pragma mark - UITableView Delegate

#pragma mark - Maintain table

//- (void)_createdNewPost:(JYPost *)post
//{
//    if (!post)
//    {
//        return;
//    }
//
//    [[JYLocalDataManager sharedInstance] insertObjects:@[post] ofClass:JYPost.class];
//
//    self.oldestPostId = post.postId;
//
//    [self.postList insertObject:post atIndex:0];
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//    [self.tableView beginUpdates];
//    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
//    [self.tableView endUpdates];
//}

- (void)_receivedOldPosts:(NSMutableArray *)postList
{
    if ([postList count] == 0) // no more old post, do nothing
    {
        return;
    }

    [self.postList addObjectsFromArray:postList];
    [self.tableView reloadData];
    [self.tableView.mj_footer endRefreshing];
}

#pragma mark - AWS S3

- (void)_createPostWithImage:(UIImage *)image contentType:(NSString *)contentType caption:(NSString *)caption
{
//    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"timeline"]];
//
//    NSData *imageData = UIImageJPEGRepresentation(image, kPhotoQuality);
//    [imageData writeToURL:fileURL atomically:YES];
//
//    NSString *s3filename = [[JYFilename sharedInstance] randomFilenameWithHttpContentType:contentType];
//    NSString *s3region = [JYFilename sharedInstance].region;
//    NSString *s3url = [NSString stringWithFormat:@"%@:%@", s3region, s3filename];
//
//    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
//    if (!transferManager)
//    {
//        NSLog(@"Error: no S3 transferManager");
//        return;
//    }
//
//    AWSS3TransferManagerUploadRequest *request = [AWSS3TransferManagerUploadRequest new];
//    request.bucket = [JYFilename sharedInstance].postBucketName;
//    request.key = s3filename;
//    request.body = fileURL;
//    request.contentType = contentType;
//
//    __weak typeof(self) weakSelf = self;
//    [[transferManager upload:request] continueWithBlock:^id(AWSTask *task) {
//        if (task.error)
//        {
//            if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain])
//            {
//                switch (task.error.code)
//                {
//                    case AWSS3TransferManagerErrorCancelled:
//                    case AWSS3TransferManagerErrorPaused:
//                        break;
//                    default:
//                        NSLog(@"Error: AWSS3TransferManager upload error = %@", task.error);
//                        break;
//                }
//            }
//            else
//            {
//                // Unknown error.
//                NSLog(@"Error: AWSS3TransferManager upload error = %@", task.error);
//            }
//        }
//        if (task.result)
//        {
//            AWSS3TransferManagerUploadOutput *uploadOutput = task.result;
//            NSLog(@"Success: AWSS3TransferManager upload task.result = %@", uploadOutput);
//            [weakSelf _createPostRecordWithS3URL:s3url caption:caption localImage:image];
//        }
//        return nil;
//    }];
}

#pragma mark - Network

- (void)_fetchUserline
{
    if ([JYCredential current].tokenValidInSeconds <= 0)
    {
        __weak typeof(self) weakSelf = self;
        self.pendingAction = ^{
            [weakSelf _fetchUserline];
        };
        return;
    }

    self.pendingAction = nil;

    if (self.networkThreadCount > 0)
    {
        return;
    }

    uint64_t month = self.month.value;
    self.month = [self.month prev];
    [self _fetchUserlineOfMonth:month];
}

- (void)_fetchUserlineOfMonth:(uint64_t)month
{
    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    NSString *url = [NSString apiURLWithPath:@"post/userline"];
    NSDictionary *parameters = @{@"userid": @([self.user.userId unsignedLongLongValue]), @"month": @(month)};

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"post/userline fetch success responseObject: %@", responseObject);

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

             [weakSelf _receivedOldPosts:postList];
             [weakSelf _networkThreadEnd];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"Error: post/userline fetch failed with error: %@", error);
             [weakSelf _networkThreadEnd];
         }
     ];
}

@end
