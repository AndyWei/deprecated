//
//  JYProfileCreationViewController.m
//  joyyios
//
//  Created by Ping Yang on 12/29/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYAvatarCreator.h"
#import "JYButton.h"
#import "JYFilename.h"
#import "JYProfileCreationViewController.h"
#import "JYYRS.h"
#import "NSDate+Joyy.h"
#import "OnboardingContentViewController.h"

@interface JYProfileCreationViewController () <JYAvatarCreatorDelegate>
@property (nonatomic) BOOL isUploading;
@property (nonatomic) JYAvatarCreator *avatarCreator;
@property (nonatomic) JYButton *cameraButton;
@property (nonatomic) JYButton *boyButton;
@property (nonatomic) JYButton *girlButton;
@property (nonatomic) JYButton *submitButton;
@property (nonatomic) NSInteger sex;
@property (nonatomic) OnboardingContentViewController *avatarPage;
@property (nonatomic) OnboardingContentViewController *sexPage;
@property (nonatomic) UIImage *iconImage;
@end

static const CGFloat kCameraButtonWidth = 80;
static const CGFloat kSubmitButtonWidth = 80;
static const CGFloat kSexButtonWidth = 150;
static const CGFloat kSexButtonInset = 30;

@implementation JYProfileCreationViewController

- (instancetype)init
{
    if (self = [super init])
    {
        [self commonInit];
        self.viewControllers = @[self.avatarPage, self.sexPage];
        
        self.allowSkipping = NO;
        self.backgroundImage = [UIImage imageNamed:@"profile_bg"];
        self.fadePageControlOnLastPage = YES;
        self.shouldFadeTransitions = YES;
//        self.swipingEnabled = NO;

        self.sex = -1;
        self.isUploading = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Property

- (UIImage *)iconImage
{
    if (!_iconImage)
    {
        _iconImage = [UIImage imageNamed:@"wink"];
    }
    return _iconImage;
}

- (JYAvatarCreator *)avatarCreator
{
    if (!_avatarCreator)
    {
        _avatarCreator = [[JYAvatarCreator alloc] initWithViewController:self];
        _avatarCreator.delegate = self;
    }
    return _avatarCreator;
}

- (JYButton *)cameraButton
{
    if (!_cameraButton) {
        CGRect frame = CGRectMake(0, SCREEN_HEIGHT - 200, kCameraButtonWidth, kCameraButtonWidth);
        JYButton *button = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
        button.centerX = SCREEN_WIDTH / 2;
        button.imageView.image = [UIImage imageNamed:@"camera"];
        [button addTarget:self action:@selector(_didTapCameraButton) forControlEvents:UIControlEventTouchUpInside];

        button.contentColor = JoyyBlue;
        button.contentAnimateToColor = JoyyWhitePure;
        button.foregroundColor = ClearColor;
        button.foregroundAnimateToColor = JoyyBlue;
        button.cornerRadius = kCameraButtonWidth / 2;

        _cameraButton = button;
    }
    return _cameraButton;
}

- (JYButton *)submitButton
{
    if (!_submitButton) {
        CGRect frame = CGRectMake(0, SCREEN_HEIGHT - 200, kSubmitButtonWidth, kSubmitButtonWidth);
        JYButton *button = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
        button.centerX = SCREEN_WIDTH / 2;
        button.imageView.image = [UIImage imageNamed:@"checkMark"];
        [button addTarget:self action:@selector(_didTapSubmitButton) forControlEvents:UIControlEventTouchUpInside];

        button.contentColor = JoyyBlue;
        button.contentAnimateToColor = JoyyWhitePure;
        button.foregroundColor = ClearColor;
        button.cornerRadius = kSubmitButtonWidth / 2;

        button.borderWidth = 4;

        _submitButton = button;
    }
    return _submitButton;
}

- (JYButton *)boyButton
{
    if (!_boyButton) {
        CGRect frame = CGRectMake(SCREEN_WIDTH - kSexButtonInset - kSexButtonWidth, 250, kSexButtonWidth, kSexButtonWidth);
        JYButton *button = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleImageWithSubtitle appearanceIdentifier:nil];
        button.imageView.image = [UIImage imageNamed:@"boy"];
        button.detailTextLabel.text = NSLocalizedString(@"Boy", nil);
        [button addTarget:self action:@selector(_didTapBoyButton) forControlEvents:UIControlEventTouchUpInside];

        button.contentColor = JoyyBlue;
        button.foregroundColor = ClearColor;
        button.cornerRadius = kSexButtonWidth / 2;

        _boyButton = button;
    }
    return _boyButton;
}

- (JYButton *)girlButton
{
    if (!_girlButton) {
        CGRect frame = CGRectMake(kSexButtonInset, 250, kSexButtonWidth, kSexButtonWidth);
        JYButton *button = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleImageWithSubtitle appearanceIdentifier:nil];
        button.imageView.image = [UIImage imageNamed:@"girl"];
        button.detailTextLabel.text = NSLocalizedString(@"Girl", nil);
        [button addTarget:self action:@selector(_didTapGirlButton) forControlEvents:UIControlEventTouchUpInside];

        button.contentColor = JoyyPink;
        button.foregroundColor = ClearColor;
        button.cornerRadius = kSexButtonWidth / 2;

        _girlButton = button;
    }
    return _girlButton;
}

- (OnboardingContentViewController *)avatarPage
{
    if (!_avatarPage)
    {
        __weak typeof(self) weakSelf = self;
        NSString *title = NSLocalizedString(@"Would you mind upload a portrait photo?", nil);
        _avatarPage = [OnboardingContentViewController contentWithTitle:title body:nil image:self.iconImage buttonText:nil action:nil];

        __weak typeof(_sexPage) weakPage = _avatarPage;
        _avatarPage.viewDidLoadBlock = ^{
            [weakPage.view addSubview:weakSelf.cameraButton];
        };
    }
    return _avatarPage;
}

- (OnboardingContentViewController *)sexPage
{
    if (!_sexPage)
    {
        __weak typeof(self) weakSelf = self;
        NSString *title = NSLocalizedString(@"Your are a", nil);
        _sexPage = [OnboardingContentViewController contentWithTitle:title body:nil image:self.iconImage buttonText:nil action:nil];

        __weak typeof(_sexPage) weakPage = _sexPage;
        _sexPage.viewDidLoadBlock = ^{
            [weakPage.view addSubview:weakSelf.girlButton];
            [weakPage.view addSubview:weakSelf.boyButton];
            [weakPage.view addSubview:weakSelf.submitButton];
            weakSelf.submitButton.hidden = YES;
        };
    }
    return _sexPage;
}

#pragma mark - Actions

- (void)_didTapCameraButton
{
    [self.avatarCreator showCamera];
}

- (void)_didTapSubmitButton
{
    if (self.sex >= 0)
    {
        [self _createProfileRecord];
    }
}

- (void)_didTapBoyButton
{
    self.sex = 1;
    self.boyButton.foregroundColor = JoyyBlue50;
    self.girlButton.foregroundColor = ClearColor;

    self.submitButton.contentColor = JoyyBlue;
    self.submitButton.foregroundAnimateToColor = JoyyBlue;
    self.submitButton.borderColor = JoyyBlue;
    self.submitButton.hidden = NO;
}

- (void)_didTapGirlButton
{
    self.sex = 0;
    self.boyButton.foregroundColor = ClearColor;
    self.girlButton.foregroundColor = JoyyPink50;

    self.submitButton.contentColor = JoyyPink;
    self.submitButton.foregroundAnimateToColor = JoyyPink;
    self.submitButton.borderColor = JoyyPink;
    self.submitButton.hidden = NO;
}

#pragma mark - JYAvatarCreatorDelegate

- (void)creator:(JYAvatarCreator *)creator didTakePhoto:(UIImage *)image
{
    self.backgroundImage = image;

     __weak typeof(self) weakSelf = self;
    [self.avatarCreator uploadAvatarImage:image success:^{
        [weakSelf moveNextPage];
    } failure:nil];
}

#pragma mark - Network

- (void)_createProfileRecord
{
    NSDictionary *parameters = [self _profileCreationParameters];
    [self.avatarCreator writeRemoteProfileWithParameters:parameters success:^{

        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidCreateProfile object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUserYRSReady object:nil];
    } failure:^(NSError *error) {
        NSString *errorMessage = nil;
        errorMessage = [error.userInfo valueForKey:NSLocalizedDescriptionKey];

        [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                       message:errorMessage
               backgroundColor:FlatYellow
                     textColor:FlatBlack
                          time:5];
    }];
}

- (NSDictionary *)_profileCreationParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    // phone
    NSString *phoneNumber = [JYCredential current].phoneNumber;
    [parameters setObject:phoneNumber forKey:@"phone"];

    // YRS
    uint64_t yrsValue = [JYCredential current].yrsValue;
    JYYRS *yrs = [JYYRS yrsWithValue:yrsValue];
    yrs.sex = self.sex;
    yrs.region = [[JYFilename sharedInstance].region integerValue];

    [JYCredential current].yrsValue = yrs.value;
    [JYFriend myself].yrsValue = yrs.value;
    [parameters setObject:@(yrs.value) forKey:@"yrs"];
    [parameters setObject:@YES forKey:@"boardcast"];
    
    return parameters;
}

@end
