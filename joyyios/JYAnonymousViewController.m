//
//  JYAnonymousViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/25/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
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

@property(nonatomic) NSMutableArray *mediaList;
@property(nonatomic) NSIndexPath *selectedIndexPath;

@end


static NSString *const kMediaCellIdentifier = @"mediaCell";

@implementation JYAnonymousViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Anonymous", nil);

    UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(_cameraButtonPressed)];
    self.navigationItem.rightBarButtonItem = cameraButton;

    self.selectedIndexPath = nil;

    self.mediaList = [NSMutableArray new];

    [self _createTableView];
    [self _fetchMedia];
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
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.backgroundColor = FlatBlack;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[JYMediaViewCell class] forCellReuseIdentifier:kMediaCellIdentifier];
    [self.view addSubview:self.tableView];

    // Add UIRefreshControl
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(_fetchMedia) forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = self.refreshControl;
}

- (JYMedia *)_meidaAt:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    return self.mediaList[index];
}

- (void)_cameraButtonPressed
{
    [TGCameraColor setTintColor:JoyyBlue];
    TGCameraNavigationController *camera = [TGCameraNavigationController newWithCameraDelegate:self];

    [self presentViewController:camera animated:YES completion:nil];
}

#pragma mark - TGCameraDelegate Methods

- (void)cameraDidCancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraDidTakePhoto:(UIImage *)photo
{
    [self dismissViewControllerAnimated:YES completion:nil];

    UIImage *image = [UIImage imageWithImage:photo scaledToSize:CGSizeMake(kPhotoWidth, kPhotoWidth)];
    NSData *imageData = UIImageJPEGRepresentation(image, kPhotoQuality);
    [self _uploadImageNamed:[JYPhotoName name] withData:imageData];
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

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

//    __weak typeof(self) weakSelf = self;

    [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData){

        [formData appendPartWithFileData:imageData name:@"file" fileName:filename mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {

        NSLog(@"Success: %@ ***** %@", operation.responseString, responseObject);

        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [KVNProgress dismiss];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@ ***** %@", operation.responseString, error);

        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [KVNProgress dismiss];

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

- (void)_fetchMedia
{
    [self _fetchMediaForBottomCells:NO];
}

- (void)_fetchMediaForBottomCells:(BOOL)isForBttomCells
{
    if (self.networkThreadCount > 0)
    {
        return;
    }

    [self networkThreadBegin];

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
             [weakSelf networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf networkThreadEnd];
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
