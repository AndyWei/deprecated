//
//  JYPhotoCaptionViewController.m
//  joyyios
//
//  Created by Ping Yang on 7/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYButton.h"
#import "JYPhotoCaptionViewController.h"

@interface JYPhotoCaptionViewController ()

@property (nonatomic) UIImage *photo;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UITextView *textView;
@property (nonatomic, weak) id<TGCameraDelegate> delegate;

@end

static NSString *const kImageCellIdentifier = @"imageCell";

const CGFloat  kTextViewHeight = 60;

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

    NSString *text = NSLocalizedString(@"Send", nil);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:text style:UIBarButtonItemStyleDone target:self action:@selector(_send)];

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
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, kTextViewHeight)];
        _textView.font = [UIFont systemFontOfSize:14];
        _textView.backgroundColor = FlatBlack;
        _textView.textColor = FlatWhite;
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
        [cell addSubview:self.textView];
        [self.textView becomeFirstResponder];
    }

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.row == 0) ? SCREEN_WIDTH : kTextViewHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Overriden Method


@end
