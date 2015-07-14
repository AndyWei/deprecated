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
@property (nonatomic) NSCache *cachePhoto;
@property (nonatomic, weak) id<TGCameraDelegate> delegate;
@property (nonatomic, weak) UIImageView *imageView;

@end

@implementation JYPhotoCaptionViewController

+ (instancetype)newWithDelegate:(id<TGCameraDelegate>)delegate photo:(UIImage *)photo
{
    JYPhotoCaptionViewController *viewController = [JYPhotoCaptionViewController newController];

    if (viewController) {
        viewController.delegate = delegate;
        viewController.photo = photo;
        viewController.cachePhoto = [[NSCache alloc] init];
    }

    return viewController;
}

+ (instancetype)newController
{
    return [super new];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barTintColor = FlatBlack;
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: JoyyGray}];

    self.view.backgroundColor = JoyyBlack;
    self.title = NSLocalizedString(@"Caption", nil);

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"CameraBack"] style:UIBarButtonItemStylePlain target:self action:@selector(_back)];

    NSString *text = NSLocalizedString(@"Send", nil);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:text style:UIBarButtonItemStyleDone target:self action:@selector(_send)];

    [self _createImageView];
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

- (void)_createImageView
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH)];
    imageView.image = self.photo;
    [self.view addSubview:imageView];
    self.imageView = imageView;
}

@end
