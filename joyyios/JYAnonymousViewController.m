//
//  JYAnonymousViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/25/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <MJRefresh/MJRefresh.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "AppDelegate.h"
#import "JYAnonymousViewController.h"
#import "JYButton.h"
#import "JYCameraOverlayView.h"
#import "JYMedia.h"
#import "JYMediaViewCell.h"
#import "JYUser.h"
#import "TGCameraColor.h"
#import "UICustomActionSheet.h"
#import "UIImage+Joyy.h"

@interface JYAnonymousViewController ()

@property(nonatomic) NSInteger networkThreadCount;
@property(nonatomic) NSMutableArray *mediaList;
@property(nonatomic) UIColor *originalTabBarTintColor;
@property(nonatomic) JYButton *cameraButton;
@property(nonatomic) UITableView *tableView;

@end

const CGFloat kCamerButtonWidth = 50;
static NSString *const kMediaCellIdentifier = @"mediaCell";

@implementation JYAnonymousViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Anonymous", nil);

    // Do not use UIBarStyleBlack in the next line, because it will make the status bar text white, which is not what we want
    // self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

    // Setup the navigationBar appearence
    self.navigationController.navigationBar.barTintColor = JoyyBlack;
    self.navigationController.navigationBar.translucent = YES;
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: JoyyGray}];

    self.networkThreadCount = 0;
    self.mediaList = [NSMutableArray new];

    [self.view addSubview:self.tableView];
    [self.view addSubview:self.cameraButton];
    [self _fetchNewMedia];

    self.originalTabBarTintColor = self.tabBarController.tabBar.barTintColor;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_like:) name:kNotificationDidLikeMedia object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.barTintColor = JoyyBlack;
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
        [_tableView registerClass:[JYMediaViewCell class] forCellReuseIdentifier:kMediaCellIdentifier];

        // Setup the pull-down-to-refresh header
        MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(_fetchNewMedia)];
        header.lastUpdatedTimeLabel.hidden = YES;
        header.stateLabel.hidden = YES;
        _tableView.header = header;

        // Setup the pull-up-to-refresh footer
        MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(_fetchOldMedia)];
        footer.refreshingTitleHidden = YES;
        footer.stateLabel.hidden = YES;
        _tableView.footer = footer;
    }
    return _tableView;
}

- (JYButton *)cameraButton
{
    if (!_cameraButton)
    {
        CGRect frame = CGRectMake(0, 0, kCamerButtonWidth, kCamerButtonWidth);
        _cameraButton = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
        _cameraButton.centerX = self.view.centerX;
        _cameraButton.centerY = SCREEN_HEIGHT - self.tabBarController.tabBar.height;

        _cameraButton.imageView.image = [UIImage imageNamed:@"CameraShot"];
        _cameraButton.contentColor = JoyyWhite50;
        _cameraButton.contentAnimateToColor = JoyyBlue;
        _cameraButton.foregroundColor = ClearColor;
        [_cameraButton addTarget:self action:@selector(_showCamera) forControlEvents:UIControlEventTouchDown];
    }
    return _cameraButton;
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

- (void)_like:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (info)
    {
        id value = [info objectForKey:@"media"];
        if (value != [NSNull null])
        {
            JYMedia *media = (JYMedia *)value;
            [self _likeMedia:media];
        }
    }
}

- (JYMedia *)_meidaAt:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    return self.mediaList[index];
}

- (void)_showCamera
{
    [TGCameraColor setTintColor:JoyyBlue];
    TGCameraNavigationController *camera = [TGCameraNavigationController newWithCameraDelegate:self];
    camera.title = self.title;

    [self presentViewController:camera animated:NO completion:nil];
}

- (void)_quickShow:(UIImage *)image withCaption:(NSString *)caption
{
    JYMedia *media = [[JYMedia alloc] initWithLocalImage:image];
    media.caption = caption;
    if (self.mediaList.count > 0)
    {
        JYMedia *lastMedia = self.mediaList.lastObject;
        media.mediaId = lastMedia.mediaId; // Make sure the future _fetchNewMedia call get the correct last media id
    }

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mediaList insertObject:media atIndex:0];
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    });
}

#pragma mark - TGCameraDelegate Methods

- (void)cameraDidCancel
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)cameraDidTakePhoto:(UIImage *)photo withCaption:(NSString *)caption
{
    // Default caption
    caption = (caption.length == 0) ? @"(ᵔᴥᵔ)" : caption;

    // Handling and upload the photo
    UIImage *image = [UIImage imageWithImage:photo scaledToSize:CGSizeMake(kPhotoWidth, kPhotoWidth)];
    NSData *imageData = UIImageJPEGRepresentation(image, kPhotoQuality);
    [self _uploadImageNamed:[JYMedia newFilename] withData:imageData andCaption:caption];

    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        // QuickShow is to make the user feel speedy before the uploading has been really done
        [weakSelf _quickShow:photo withCaption:caption];
    }];
}

- (void)cameraDidSelectAlbumPhoto:(UIImage *)image withCaption:(NSString *)caption
{
    [self cameraDidTakePhoto:image withCaption:caption];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.mediaList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYMediaViewCell *cell =
    (JYMediaViewCell *)[tableView dequeueReusableCellWithIdentifier:kMediaCellIdentifier forIndexPath:indexPath];

    JYMedia *media = [self _meidaAt:indexPath];
    cell.media = media;

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYMedia *media = [self _meidaAt:indexPath];
    return [JYMediaViewCell heightForMedia:media];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Maintain table

- (void)_updateTableWithMedia:(NSArray *)mediaList toEnd:(BOOL)toEnd
{
    if (!mediaList.count)
    {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self _addMedia:mediaList toEnd:toEnd];
        [self.tableView reloadData];
    });
}

- (void)_addMedia:(NSArray *)mediaList toEnd:(BOOL)toEnd
{
    if (!mediaList.count)
    {
        return;
    }

    // The items in mediaList are DESC sorted by media_id
    if (toEnd)
    {
        [self.mediaList addObjectsFromArray:mediaList];
    }
    else
    {
        for (JYMedia *media in [mediaList reverseObjectEnumerator])
        {
            [self.mediaList insertObject:media atIndex:0];
        }
    }
}

#pragma mark - Network

- (void)_likeMedia:(JYMedia *)media
{
    [self _networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"media/like"];
    NSDictionary *parameters = @{@"id": @(media.mediaId)};

    __weak typeof(self) weakSelf = self;
    [manager POST:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"media/like POST success responseObject: %@", responseObject);

             NSDictionary *dict = (NSDictionary *)responseObject;
             media.likeCount = [[dict objectForKey:@"like_count"] unsignedIntegerValue];
             [weakSelf.tableView reloadData];
             [weakSelf _networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf _networkThreadEnd];
         }
     ];
}

- (void)_uploadImageNamed:(NSString *)filename withData:(NSData *)imageData andCaption:(NSString *)caption
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"media"];
    NSMutableDictionary *parameters = [self _uploadImageParameters];

    [parameters setObject:caption forKey:@"caption"];
    NSLog(@"parameters: %@", parameters);

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData){

        [formData appendPartWithFileData:imageData name:@"file" fileName:filename mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {

        NSLog(@"Image upload success: %@", responseObject);

        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Image upload error: %@ ***** %@", operation.responseString, error);

        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

        [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                       message:error.localizedDescription
               backgroundColor:FlatYellow
                     textColor:FlatBlack
                          time:5];
    }];
}

- (NSMutableDictionary *)_uploadImageParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:@(0) forKey:@"media_type"]; // TODO: define media type

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [parameters setObject:@(appDelegate.currentCoordinate.latitude) forKey:@"lat"];
    [parameters setObject:@(appDelegate.currentCoordinate.longitude) forKey:@"lon"];

    return parameters;
}

- (void)_fetchNewMedia
{
    [self _fetchMediaToEnd:NO];
}

- (void)_fetchOldMedia
{
    [self _fetchMediaToEnd:YES];
}

- (void)_fetchMediaToEnd:(BOOL)toEnd
{
    if (self.networkThreadCount > 0)
    {
        return;
    }

    [self _networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"media/nearby"];
    NSDictionary *parameters = [self _fetchMediaHttpParameters:toEnd];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
//             NSLog(@"media/nearby fetch success responseObject: %@", responseObject);

             NSMutableArray *mediaList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 JYMedia *media = [[JYMedia alloc] initWithDictionary:dict];
                 [mediaList addObject:media];
             }
             [weakSelf _fetchBriefForMediaList:mediaList toEnd:toEnd];
             [weakSelf _networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf _networkThreadEnd];
         }
     ];
}

- (void)_fetchBriefForMediaList:(NSArray *)mediaList toEnd:(BOOL)toEnd
{
    if (!mediaList.count)
    {
        return;
    }

    [self _networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"media/brief"];
    NSDictionary *parameters = [self _fetchBriefHttpParameters:mediaList];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"media/brief fetch success responseObject: %@", responseObject);

             NSUInteger count = mediaList.count;
             for (NSUInteger i = 0; i < count; i++)
             {
                 JYMedia *media = (JYMedia *)mediaList[i];
                 NSDictionary *brief = (NSDictionary *)responseObject[i];
                 [media setBrief:brief];
             }
             [weakSelf _updateTableWithMedia:mediaList toEnd:toEnd];
             [weakSelf _networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf _networkThreadEnd];
         }
     ];
}



- (NSDictionary *)_fetchMediaHttpParameters:(BOOL)toEnd
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D currentPoint = appDelegate.currentCoordinate;
    [parameters setValue:@(currentPoint.longitude) forKey:@"lon"];
    [parameters setValue:@(currentPoint.latitude) forKey:@"lat"];
    [parameters setValue:@(2) forKey:@"distance"];

    if (self.mediaList.count > 0)
    {
        if (toEnd)
        {
            JYMedia *media = self.mediaList.lastObject;
            [parameters setValue:@(media.mediaId) forKey:@"before"];
        }
        else
        {
            JYMedia *media = self.mediaList.firstObject;
            [parameters setValue:@(media.mediaId) forKey:@"after"];
        }
    }

    NSLog(@"fetchMedia parameters: %@", parameters);
    return parameters;
}

- (NSDictionary *)_fetchBriefHttpParameters:(NSArray *)mediaList
{
    NSMutableArray *mediaIds = [NSMutableArray new];
    for (JYMedia *media in mediaList)
    {
        [mediaIds addObject:@(media.mediaId)];
    }

    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setValue:mediaIds forKey:@"id"];

    return parameters;
}

@end
