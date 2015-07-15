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
#import "JYPhotoName.h"
#import "JYUser.h"
#import "TGCameraColor.h"
#import "UICustomActionSheet.h"
#import "UIImage+Joyy.h"

@interface JYAnonymousViewController ()

@property(nonatomic) BOOL needReloadTable;
@property(nonatomic) NSInteger networkThreadCount;
@property(nonatomic) NSMutableArray *mediaList;
@property(nonatomic) NSIndexPath *selectedIndexPath;
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

    self.needReloadTable = NO;
    self.networkThreadCount = 0;
    self.selectedIndexPath = nil;

    self.mediaList = [NSMutableArray new];

    [self.view addSubview:self.tableView];
    [self.view addSubview:self.cameraButton];
    [self _fetchNewMedia];

    self.originalTabBarTintColor = self.tabBarController.tabBar.barTintColor;
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
        _cameraButton.contentColor = JoyyGray50;
        _cameraButton.contentAnimateToColor = JoyyGray;
        _cameraButton.foregroundColor = ClearColor;
        [_cameraButton addTarget:self action:@selector(_showCamera) forControlEvents:UIControlEventTouchUpInside];
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
        if (self.needReloadTable)
        {
            self.needReloadTable = NO;
            [self.tableView reloadData];
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
    // fetch new media here is to prefare for the QuickShow
    [self _fetchNewMedia];

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
    [self.mediaList insertObject:media atIndex:0];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
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
    [self _uploadImageNamed:[JYPhotoName name] withData:imageData andCaption:caption];

    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:NO completion:^{
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

#pragma mark - Network

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
    [self _fetchMediaForBottomCells:NO];
}

- (void)_fetchOldMedia
{
    [self _fetchMediaForBottomCells:YES];
}

- (void)_fetchMediaForBottomCells:(BOOL)isForBttomCells
{
    if (self.networkThreadCount > 0)
    {
        return;
    }

    [self _networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"media/nearby"];
    NSDictionary *parameters = [self _fetchMediaHttpParameters:isForBttomCells];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"media/nearby paid fetch success responseObject: %@", responseObject);

             if (isForBttomCells)
             {
                 for (NSDictionary *dict in responseObject)
                 {
                     JYMedia *media = [[JYMedia alloc] initWithDictionary:dict];
                     [weakSelf.mediaList addObject:media];
                 }
             }
             else
             {
                 for (NSDictionary *dict in [responseObject reverseObjectEnumerator])
                 {
                     JYMedia *media = [[JYMedia alloc] initWithDictionary:dict];
                     [weakSelf.mediaList insertObject:media atIndex:0];
                 }
             }

             self.needReloadTable = [(NSArray *)responseObject count] > 0;
             [weakSelf _networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf _networkThreadEnd];
         }
     ];
}

- (NSDictionary *)_fetchMediaHttpParameters:(BOOL)isForBttomCells
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D currentPoint = appDelegate.currentCoordinate;
    [parameters setValue:@(currentPoint.longitude) forKey:@"lon"];
    [parameters setValue:@(currentPoint.latitude) forKey:@"lat"];
    [parameters setValue:@(2) forKey:@"distance"];

    if (self.mediaList.count > 0)
    {
        if (isForBttomCells)
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

@end
