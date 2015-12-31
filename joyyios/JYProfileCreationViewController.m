//
//  JYProfileCreationViewController.m
//  joyyios
//
//  Created by Ping Yang on 12/29/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

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
@property (nonatomic) JYButton *boyButton;
@property (nonatomic) JYButton *girlButton;
@property (nonatomic) NSInteger sex;
@property (nonatomic) OnboardingContentViewController *avatarPage;
@property (nonatomic) OnboardingContentViewController *sexPage;
@property (nonatomic) UIImage *iconImage;
@end

static const CGFloat kButtonWidth = 150;
static const CGFloat kButtonInset = 30;

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
        self.swipingEnabled = NO;

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

- (JYButton *)boyButton
{
    if (!_boyButton) {
        CGRect frame = CGRectMake(SCREEN_WIDTH - kButtonInset - kButtonWidth, 250, kButtonWidth, kButtonWidth);
        JYButton *button = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleImageWithSubtitle appearanceIdentifier:nil];
        button.imageView.image = [UIImage imageNamed:@"boy"];
        button.detailTextLabel.text = NSLocalizedString(@"Boy", nil);
        [button addTarget:self action:@selector(_didTapBoyButton) forControlEvents:UIControlEventTouchUpInside];

        button.contentColor = JoyyBlue;
        button.foregroundColor = ClearColor;
        button.cornerRadius = kButtonWidth / 2;

        _boyButton = button;
    }
    return _boyButton;
}

- (JYButton *)girlButton
{
    if (!_girlButton) {
        CGRect frame = CGRectMake(kButtonInset, 250, kButtonWidth, kButtonWidth);
        JYButton *button = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleImageWithSubtitle appearanceIdentifier:nil];
        button.imageView.image = [UIImage imageNamed:@"girl"];
        button.detailTextLabel.text = NSLocalizedString(@"Girl", nil);
        [button addTarget:self action:@selector(_didTapGirlButton) forControlEvents:UIControlEventTouchUpInside];

        button.contentColor = JoyyRed;
        button.foregroundColor = ClearColor;
        button.cornerRadius = kButtonWidth / 2;

        _girlButton = button;
    }
    return _girlButton;
}

- (OnboardingContentViewController *)avatarPage
{
    if (!_avatarPage)
    {
        __weak typeof(self) weakSelf = self;
        _avatarPage = [OnboardingContentViewController contentWithTitle:NSLocalizedString(@"Let The World See You", nil)
                                                                   body:nil
                                                                  image:self.iconImage
                                                             buttonText:NSLocalizedString(@"Take Photo", nil)
                                                                 action:^{
                                                                [weakSelf.avatarCreator showCamera];
                                                            }];
    }
    return _avatarPage;
}

- (OnboardingContentViewController *)sexPage
{
    if (!_sexPage)
    {
        __weak typeof(self) weakSelf = self;
        _sexPage = [OnboardingContentViewController contentWithTitle:NSLocalizedString(@"Your are a", nil)
                                                                body:nil
                                                                image:self.iconImage
                                                            buttonText:NSLocalizedString(@"Submit", nil)
                                                              action:^{
                                                                  if (weakSelf.sex >= 0)
                                                                  {
                                                                      [weakSelf _createProfileRecord];
                                                                  }
                                                              }];

        __weak typeof(_sexPage) weakPage = _sexPage;
        _sexPage.viewDidLoadBlock = ^{
            [weakPage.view addSubview:weakSelf.girlButton];
            [weakPage.view addSubview:weakSelf.boyButton];
        };
    }
    return _sexPage;
}

#pragma mark - Actions

- (void)_didTapBoyButton
{
    self.sex = 1;
    self.boyButton.foregroundColor = JoyyBlue50;
    self.girlButton.foregroundColor = ClearColor;
}

- (void)_didTapGirlButton
{
    self.sex = 0;
    self.boyButton.foregroundColor = ClearColor;
    self.girlButton.foregroundColor = JoyyRed50;
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
    [self.avatarCreator writeRemoteProfileWithParameters:parameters];
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
