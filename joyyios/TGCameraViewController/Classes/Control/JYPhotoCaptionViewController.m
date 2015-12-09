//
//  JYPhotoCaptionViewController.m
//  joyyios
//
//  Created by Ping Yang on 7/13/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYPhotoCaptionViewController.h"
#import "TGAssetsLibrary.h"

@import AssetsLibrary;

@interface JYPhotoCaptionViewController ()
@property (nonatomic) UIImageView *imageView;
@property (nonatomic, weak) id<TGCameraDelegate> delegate;
@end

static NSString *const kImageCellIdentifier = @"imageCell";

@implementation JYPhotoCaptionViewController

- (instancetype)initWithDelegate:(id<TGCameraDelegate>)delegate
{
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self)
    {
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kImageCellIdentifier];
        self.textInputbar.textView.placeholder = NSLocalizedString(@"Add caption:", nil);
        self.delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Caption", nil);

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"CameraBack"] style:UIBarButtonItemStylePlain target:self action:@selector(_back)];

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
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    // show keyboard
    [self.textView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)canPressRightButton
{
    return YES;
}

- (void)_back
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)_send
{
    if ( [_delegate respondsToSelector:@selector(cameraWillTakePhoto)])
    {
        [_delegate cameraWillTakePhoto];
    }

    if ([_delegate respondsToSelector:@selector(cameraDidTakePhoto:fromAlbum:withCaption:)])
    {
//        [self _saveToPhotoLibary];
        [_delegate cameraDidTakePhoto:self.photo fromAlbum:self.isFromAlbum withCaption:self.textView.text];
    }
}

- (void)_saveToPhotoLibary
{
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    TGAssetsLibrary *library = [TGAssetsLibrary defaultAssetsLibrary];

    void (^saveJPGImageAtDocumentDirectory)(UIImage *) = ^(UIImage *photo) {
        [library saveJPGImageAtDocumentDirectory:_photo resultBlock:^(NSURL *assetURL) {
            [_delegate cameraDidSavePhotoAtPath:assetURL];
        } failureBlock:^(NSError *error) {
            if ([_delegate respondsToSelector:@selector(cameraDidSavePhotoWithError:)]) {
                [_delegate cameraDidSavePhotoWithError:error];
            }
        }];
    };

    if ([[TGCamera getOption:kTGCameraOptionSaveImageToAlbum] boolValue] && status != ALAuthorizationStatusDenied)
    {
        [library saveImage:_photo resultBlock:^(NSURL *assetURL) {
            if ([_delegate respondsToSelector:@selector(cameraDidSavePhotoAtPath:)])
            {
                [_delegate cameraDidSavePhotoAtPath:assetURL];
            }
        } failureBlock:^(NSError *error) {
            saveJPGImageAtDocumentDirectory(_photo);
        }];
    }
    else
    {
        if ([_delegate respondsToSelector:@selector(cameraDidSavePhotoAtPath:)])
        {
            saveJPGImageAtDocumentDirectory(_photo);
        }
    }
}

- (UIImageView *)imageView
{
    if (!_imageView)
    {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH)];
        _imageView.centerX = self.tableView.centerX;
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

- (void)setPhoto:(UIImage *)photo
{
    _photo = photo;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kImageCellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = JoyyBlack;
    [cell addSubview:self.imageView];
    self.imageView.image = self.photo;

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return SCREEN_WIDTH;
}

#pragma mark - Overriden Method

// Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
- (void)didPressRightButton:(id)sender
{
    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    [self.textView refreshFirstResponder];

    [self _send];
    [super didPressRightButton:sender];
}

@end
