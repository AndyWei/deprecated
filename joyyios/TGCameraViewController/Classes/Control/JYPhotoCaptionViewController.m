//
//  JYPhotoCaptionViewController.m
//  joyyios
//
//  Created by Ping Yang on 7/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYPhotoCaptionViewController.h"
#import "TGAssetsLibrary.h"

@import AssetsLibrary;

@interface JYPhotoCaptionViewController () <UITextViewDelegate>
@property (nonatomic) UIImage *photo;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UITextView *textView;
@property (nonatomic, weak) id<TGCameraDelegate> delegate;
@end

static NSString *const kImageCellIdentifier = @"imageCell";

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

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"send"] style:UIBarButtonItemStylePlain target:self action:@selector(_send)];

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
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(0, SCREEN_WIDTH - kCaptionLabelHeightMin, SCREEN_WIDTH, kCaptionLabelHeightMin)];
        _textView.delegate = self;
        _textView.font = [UIFont systemFontOfSize:kFontSizeCaption];
        _textView.backgroundColor = JoyyBlack50;
        _textView.textColor = JoyyWhite;
        _textView.tintColor = JoyyWhite;
        _textView.textAlignment = NSTextAlignmentCenter;
        _textView.keyboardAppearance = UIKeyboardAppearanceDark;
        _textView.scrollEnabled = NO; // Disable scroll is to fix the top padding automatically change to zero issue.
        [_textView becomeFirstResponder];
    }
    return _textView;
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
    [cell addSubview:self.textView];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return SCREEN_WIDTH;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextView Delegate

- (void)textViewDidChange:(UITextView *)textView
{
    CGSize newSize = [textView sizeThatFits:CGSizeMake(SCREEN_WIDTH, MAXFLOAT)];
    textView.height = fmin(SCREEN_WIDTH, newSize.height);
    textView.y = SCREEN_WIDTH - textView.height;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return textView.text.length + (text.length - range.length) <= 900;
}

@end
