//
//  JYPhotoCaptionViewController.m
//  joyyios
//
//  Created by Ping Yang on 7/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYButton.h"
#import "JYPhotoCaptionViewController.h"
#import "TGAssetsLibrary.h"

@import AssetsLibrary;

@interface JYPhotoCaptionViewController ()

@property (nonatomic) UIImage *photo;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIView *inputView;
@property (nonatomic) UITextView *textView;
@property (nonatomic) JYButton *sendButton;

@property (nonatomic, weak) id<TGCameraDelegate> delegate;

@end

static NSString *const kImageCellIdentifier = @"imageCell";

const CGFloat kInputViewHeight = 60;
const CGFloat kSendButtonWidth = 60;

@implementation JYPhotoCaptionViewController

+ (instancetype)newWithDelegate:(id<TGCameraDelegate>)delegate photo:(UIImage *)photo
{
    return [[JYPhotoCaptionViewController alloc] initWithWithDelegate:delegate photo:photo];
}

- (instancetype)initWithWithDelegate:(id<TGCameraDelegate>)delegate photo:(UIImage *)photo
{
    self = [super initWithStyle:UITableViewStylePlain];

    if (self)
    {
        self.delegate = delegate;
        self.photo = photo;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = FlatBlack;
    self.title = NSLocalizedString(@"Caption", nil);

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"CameraBack"] style:UIBarButtonItemStylePlain target:self action:@selector(_back)];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kImageCellIdentifier];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden
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

    if ([_delegate respondsToSelector:@selector(cameraDidTakePhoto:withCaption:)])
    {
        if (_albumPhoto)
        {
            [_delegate cameraDidSelectAlbumPhoto:_photo withCaption:self.textView.text];
        }
        else
        {
            [self _saveToPhotoLibary];
            [_delegate cameraDidTakePhoto:_photo withCaption:self.textView.text];
        }
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
        _imageView.image = self.photo;
    }
    return _imageView;
}

- (UITextView *)textView
{
    if (!_textView)
    {
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH - kSendButtonWidth, kInputViewHeight)];
        _textView.font = [UIFont systemFontOfSize:14];
        _textView.backgroundColor = FlatBlack;
        _textView.textColor = FlatWhite;
    }
    return _textView;
}

- (JYButton *)sendButton
{
    if (!_sendButton)
    {
        CGRect frame = CGRectMake(0, 0, kSendButtonWidth, kSendButtonWidth);
        _sendButton = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];

        _sendButton.imageView.image = [UIImage imageNamed:@"CameraShot"];
        _sendButton.contentColor = JoyyBlue;
        _sendButton.contentAnimateToColor = JoyyGray;
        _sendButton.foregroundColor = ClearColor;
        [_sendButton addTarget:self action:@selector(_send) forControlEvents:UIControlEventTouchUpInside];

        _sendButton.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    }
    return _sendButton;
}

- (UIView *)inputView
{
    if (!_inputView)
    {
        _inputView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, kInputViewHeight)];
        self.textView.x = 0;
        self.sendButton.x = CGRectGetMaxX(self.textView.frame);
        [_inputView addSubview:self.textView];
        [_inputView addSubview:self.sendButton];

        [self.textView becomeFirstResponder];
    }
    return _inputView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kImageCellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = FlatBlack;

    if (indexPath.row == 0)
    {
        [cell addSubview:self.imageView];
    }
    else
    {
        [cell addSubview:self.inputView];
    }

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.row == 0) ? SCREEN_WIDTH : kInputViewHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Overriden Method


@end
