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
@property(nonatomic, weak) UITableView *tableView;

@end


static NSString *const kMediaCellIdentifier = @"mediaCell";

@implementation JYAnonymousViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Anonymous", nil);

    // Do not use UIBarStyleBlack in the next line, because it will make the status bar text white, which is not what we want
    // self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

    // Setup the navigationBar appearence
    self.navigationController.navigationBar.barTintColor = FlatBlack;
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: JoyyGray}];

    UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(_cameraButtonPressed)];
    self.navigationItem.rightBarButtonItem = cameraButton;

    self.needReloadTable = NO;
    self.networkThreadCount = 0;
    self.selectedIndexPath = nil;

    self.mediaList = [NSMutableArray new];

    [self _createTableView];
    [self _fetchNewMedia];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
}

- (void)_createTableView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.backgroundColor = FlatBlack;
    tableView.separatorColor = ClearColor;
    tableView.showsHorizontalScrollIndicator = NO;
    tableView.showsVerticalScrollIndicator = NO;
    [tableView registerClass:[JYMediaViewCell class] forCellReuseIdentifier:kMediaCellIdentifier];

    // Setup the pull-down-to-refresh header
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(_fetchNewMedia)];
    header.lastUpdatedTimeLabel.hidden = YES;
    header.stateLabel.hidden = YES;
    tableView.header = header;

    // Setup the pull-up-to-refresh footer
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(_fetchOldMedia)];
    footer.refreshingTitleHidden = YES;
    footer.stateLabel.hidden = YES;
    tableView.footer = footer;

    [self.view addSubview:tableView];

    self.tableView = tableView;
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

- (void)_cameraButtonPressed
{
    // fetch new media here is to prefare for the QuickShow
    [self _fetchNewMedia];

    [TGCameraColor setTintColor:JoyyBlue];
    TGCameraNavigationController *camera = [TGCameraNavigationController newWithCameraDelegate:self];
    camera.title = self.title;
    camera.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    [self presentViewController:camera animated:YES completion:nil];
}

- (void)_quickShow:(UIImage *)image
{
    JYMedia *media = [[JYMedia alloc] initWithLocalImage:image];
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

- (void)_removeQuickShowMedia
{
    // Not sure if the right thing to do this, commented out for now
//    for (NSUInteger index = 0; index < self.mediaList.count; index++)
//    {
//        JYMedia *media = self.mediaList[index];
//        if (media.localImage)
//        {
//            [self.mediaList removeObjectAtIndex:index];
//
//            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
//            [self.tableView beginUpdates];
//            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//            [self.tableView endUpdates];
//
//            return;
//        }
//    }
}

#pragma mark - TGCameraDelegate Methods

- (void)cameraDidCancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraDidTakePhoto:(UIImage *)photo
{
    // Handling and upload the photo
    UIImage *image = [UIImage imageWithImage:photo scaledToSize:CGSizeMake(kPhotoWidth, kPhotoWidth)];
    NSData *imageData = UIImageJPEGRepresentation(image, kPhotoQuality);
    [self _uploadImageNamed:[JYPhotoName name] withData:imageData];

    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        // QuickShow is to make the user feel speedy before the uploading has been really done
        [weakSelf _quickShow:photo];
    }];
}

- (void)cameraDidSelectAlbumPhoto:(UIImage *)image
{
    [self cameraDidTakePhoto:image];
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

}

#pragma mark - UIActionSheetDelegate

-(void)customActionSheet:(UICustomActionSheet *)customActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{

}

#pragma mark - Network

- (void)_uploadImageNamed:(NSString *)filename withData:(NSData *)imageData
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"media"];
    NSMutableDictionary *parameters = [self _uploadImageParameters];
    NSLog(@"parameters: %@", parameters);

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData){

        [formData appendPartWithFileData:imageData name:@"file" fileName:filename mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {

        NSLog(@"Image upload success: %@", responseObject);

        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Image upload error: %@ ***** %@", operation.responseString, error);

        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [weakSelf _removeQuickShowMedia];

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
    [parameters setObject:@"test(ᵔᴥᵔ)" forKey:@"caption"];

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
