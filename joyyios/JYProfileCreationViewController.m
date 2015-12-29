//
//  JYProfileCreationViewController.m
//  joyyios
//
//  Created by Ping Yang on 12/29/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//


#import "JYAvatarCreator.h"
#import "JYProfileCreationViewController.h"
#import "OnboardingContentViewController.h"

@interface JYProfileCreationViewController () <JYAvatarCreatorDelegate>
@property (nonatomic) JYAvatarCreator *avatarCreator;
@property (nonatomic) OnboardingContentViewController *avatarPage;
@property (nonatomic) OnboardingContentViewController *sexPage;
@property (nonatomic) OnboardingContentViewController *yobPage;
@end

@implementation JYProfileCreationViewController

- (instancetype)init {
    if (self = [super init])
    {
        [self commonInit];
        self.viewControllers = @[self.avatarPage, self.sexPage, self.yobPage];
        
        self.allowSkipping = NO;
        self.fadePageControlOnLastPage = YES;
        self.shouldFadeTransitions = YES;
        self.swipingEnabled = YES;
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

- (JYAvatarCreator *)avatarCreator
{
    if (!_avatarCreator)
    {
        _avatarCreator = [[JYAvatarCreator alloc] initWithViewController:self];
        _avatarCreator.delegate = self;
    }
    return _avatarCreator;
}

- (OnboardingContentViewController *)avatarPage
{
    if (!_avatarPage)
    {
        __weak typeof(self) weakSelf = self;
        _avatarPage = [OnboardingContentViewController contentWithTitle:NSLocalizedString(@"Let The World See You", nil)
                                                                   body:nil
                                                                  image:[UIImage imageNamed:@"wink"]
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
//        __weak typeof(self) weakSelf = self;
        _sexPage = [OnboardingContentViewController contentWithTitle:@"Get Service Anytime Anywhere"
                                                                body:@"People arround you are glad to serve you..."
                                                                image:[UIImage imageNamed:@"blue"]
                                                            buttonText:@"Get Started"
                                                                action:^{
//                                                                    [weakSelf _introductionDidFinish];
                                                                }];
    }
    return _sexPage;
}

- (OnboardingContentViewController *)yobPage
{
    if (!_yobPage)
    {
//        __weak typeof(self) weakSelf = self;
        _yobPage = [OnboardingContentViewController contentWithTitle:@"Get Service Anytime Anywhere"
                                                                body:@"People arround you are glad to serve you..."
                                                               image:[UIImage imageNamed:@"blue"]
                                                          buttonText:@"Get Started"
                                                              action:^{
//                                                                  [weakSelf _introductionDidFinish];
                                                              }];
    }
    return _yobPage;
}

#pragma mark - JYAvatarCreatorDelegate

- (void)creator:(JYAvatarCreator *)creator didTakePhoto:(UIImage *)image
{
    self.avatarPage.imageView.image = image;
//    [self.avatarCreator uploadAvatarImage:image success:^{
//
//    } failure:^(NSError *error) {
//        NSString *errorMessage = nil;
//        errorMessage = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
//
//        [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
//                       message:errorMessage
//               backgroundColor:FlatYellow
//                     textColor:FlatBlack
//                          time:5];
//    }];
}

@end
