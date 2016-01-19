//
//  JYUserViewController.m
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <AMPopTip/AMPopTip.h>
#import <MSWeakTimer/MSWeakTimer.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "AppDelegate.h"
#import "JYButton.h"
#import "JYContactViewController.h"
#import "JYCredential.h"
#import "JYFacialGestureDetector.h"
#import "JYManagementDataStore.h"
#import "JYPeopleViewController.h"
#import "JYUserCard.h"
#import "JYYRS.h"
#import "MDCSwipeToChoose.h"
#import "NSNumber+Joyy.h"

@interface JYPeopleViewController () <JYFacialGuestureDetectorDelegate, MDCSwipeToChooseDelegate>
@property (nonatomic) AMPopTip *winkTip;
@property (nonatomic) AMPopTip *nopeTip;
@property (nonatomic) BOOL isListening;
@property (nonatomic) CGRect cardFrame;
@property (nonatomic) JYButton *nopeButton;
@property (nonatomic) JYButton *winkButton;
@property (nonatomic) JYButton *fetchButton;
@property (nonatomic) JYFacialGestureDetector *facialGesturesDetector;
@property (nonatomic) JYUser *currentUser;
@property (nonatomic) JYUserCard *frontCard;
@property (nonatomic) JYUserCard *backCard;
@property (nonatomic) MSWeakTimer *detectorAwakeTimer;
@property (nonatomic) NSMutableArray *userList;
@property (nonatomic) NSMutableString *zip;
@property (nonatomic) uint64_t minUserId;
@property (nonatomic, copy) SuccessHandler pendingAction;
@end

const CGFloat kButtonSpaceH = 80;
const CGFloat kButtonSpaceV = 40;
const CGFloat kButtonWidth = 60;

@implementation JYPeopleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = JoyyWhitePure;
    self.title = NSLocalizedString(@"People", nil);

    _cardFrame = CGRectZero;
    self.userList = [NSMutableArray new];
    self.minUserId = LLONG_MAX;

    [self.view addSubview:self.fetchButton];
    [self.view addSubview:self.nopeButton];
    [self.view addSubview:self.winkButton];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appStart) name:kNotificationAppDidStart object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appStop) name:kNotificationAppDidStop object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_apiTokenReady) name:kNotificationAPITokenReady object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didFindInContactsUsers:) name:kNotificationDidFindInContactsUsers object:nil];

    [self _fetchUsers];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([JYManagementDataStore sharedInstance].didShowPeopleViewTips)
    {
        [self _turnOnDetector];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    if (_facialGesturesDetector)
    {
        [self _turnOffDetector];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_apiTokenReady
{
    if (self.pendingAction)
    {
        self.pendingAction();
    }
}

#pragma mark - Actions

- (void)_appStart
{
    // Only turn detector on in the cases that app resume active
    if (self.userList)
    {
        [self _turnOnDetector];
    }
}

- (void)_appStop
{
    if (_facialGesturesDetector)
    {
        [self _turnOffDetector];
    }
}

- (void)_turnOnDetector
{
    // Since in the init few seconds the reportings from the detector is not accurate, we don't listening to them.
    // The awake timer will enable the reporting later

    self.isListening = NO;
    NSError *error;
    [self.facialGesturesDetector startDetectionWithError:&error];

    [self _startDetectorAwakeTimer];
}

- (void)_turnOffDetector
{
    self.isListening = NO;
    [self.facialGesturesDetector stopDetection];
    [self _stopDetectorAwakeTimer];
    self.facialGesturesDetector = nil;
}

- (void)_startDetectorAwakeTimer
{
    if (self.detectorAwakeTimer)
    {
        [self.detectorAwakeTimer invalidate];
    }

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.detectorAwakeTimer = [MSWeakTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(_awakeDetector) userInfo:nil repeats:NO dispatchQueue:queue];
}

- (void)_stopDetectorAwakeTimer
{
    if (self.detectorAwakeTimer)
    {
        [self.detectorAwakeTimer invalidate];
        self.detectorAwakeTimer = nil;
    }
}

- (void)_awakeDetector
{
    NSLog(@"AwakeTimer timeout");
    self.isListening = YES;
    [self _stopDetectorAwakeTimer];
}

- (void)_recoverNopeButton
{
    self.nopeButton.selected = NO;
}

- (void)_recoverWinkButton
{
    self.winkButton.selected = NO;
}

- (void)_didFindInContactsUsers:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (info)
    {
        id users = [info objectForKey:@"users"];
        id contacts = [info objectForKey:@"contacts"];
        if (users != [NSNull null] && contacts != [NSNull null])
        {
            NSMutableArray *userList = (NSMutableArray *)users;
            NSDictionary *contactDict = (NSDictionary *)contacts;
            JYContactViewController *vc = [[JYContactViewController alloc] initWithUserList:userList contactDictionay:contactDict];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
            [self.navigationController presentViewController:nc animated:YES completion:nil];
        }
    }

    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - MDCSwipeToChooseDelegate Methods

// Disable facial guesture during swipe
- (void)viewDidStartSwipe:(UIView *)view
{
    self.isListening = NO;
}

// Enable facial guesture during swipe
- (void)viewDidCancelSwipe:(UIView *)view
{
    self.isListening = YES;
}

- (void)view:(UIView *)view wasChosenWithDirection:(MDCSwipeDirection)direction
{
    if (direction == MDCSwipeDirectionLeft)
    {
//        NSLog(@"You noped %@.", self.currentPerson.username);
    }
    else
    {
        [self _wink:self.currentUser];
    }

    // MDCSwipeToChooseView has removed the frontCard from the view hierarchy after it is swiped.
    // So, we move the backCard to the front, and create a new backCard.
    self.frontCard = self.backCard;

    self.isListening = (self.frontCard != nil);

    if ((self.backCard = [self popCard]))
    {
        [self.view insertSubview:self.backCard belowSubview:self.frontCard];
    }
}

#pragma mark - JYFacialDetectorDelegate Methods

- (void)detectorDidDetectLeftWink:(JYFacialGestureDetector *)detector
{
    self.nopeButton.selected = YES;
    [self.nopeButton sendActionsForControlEvents:UIControlEventTouchUpInside];

    [self performSelector:@selector(_recoverNopeButton) withObject:self afterDelay:0.4f];
}

- (void)detectorDidDetectRightWink:(JYFacialGestureDetector *)detector
{
    self.winkButton.selected = YES;
    [self.winkButton sendActionsForControlEvents:UIControlEventTouchUpInside];

    [self performSelector:@selector(_recoverWinkButton) withObject:self afterDelay:0.4f];
}

#pragma mark - Properties

- (JYButton *)fetchButton
{
    if (!_fetchButton)
    {
        _fetchButton = [JYButton button];
        _fetchButton.x = 50;
        _fetchButton.y = CGRectGetMidY(self.cardFrame);
        _fetchButton.width = SCREEN_WIDTH - 100;
        _fetchButton.cornerRadius = 5;

        _fetchButton.textLabel.text = NSLocalizedString(@"Give Me More", nil);
        [_fetchButton addTarget:self action:@selector(_fetchUsers) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fetchButton;
}

- (JYButton *)nopeButton
{
    if (!_nopeButton)
    {
        CGRect frame = CGRectMake(kButtonSpaceH, CGRectGetMaxY(self.cardFrame) + kButtonSpaceV, kButtonWidth, kButtonWidth);
        UIImage *image = [UIImage imageNamed:@"nope"];
        _nopeButton = [JYButton iconButtonWithFrame:frame icon:image color:FlatYellowDark];
        _nopeButton.contentAnimateToColor = JoyyWhite;

        [_nopeButton addTarget:self action:@selector(_nope) forControlEvents:UIControlEventTouchUpInside];
    }
    return _nopeButton;
}

- (JYButton *)winkButton
{
    if (!_winkButton)
    {
        CGRect frame = CGRectMake(CGRectGetMaxX(self.view.frame) - kButtonWidth - kButtonSpaceH,
                                  CGRectGetMaxY(self.cardFrame) + kButtonSpaceV,
                                  kButtonWidth,
                                  kButtonWidth);

        UIImage *image = [UIImage imageNamed:@"wink"];
        _winkButton = [JYButton iconButtonWithFrame:frame icon:image color:JoyyBlue];
        _winkButton.contentAnimateToColor = JoyyWhite;

        [_winkButton addTarget:self action:@selector(_wink) forControlEvents:UIControlEventTouchUpInside];
    }
    return _winkButton;
}

- (CGRect)cardFrame
{
    if (_cardFrame.size.height == 0)
    {
        CGFloat paddingLeft = 10.f;
        CGFloat paddingTop = 84.f;

        CGFloat width = CGRectGetWidth(self.view.frame) - (paddingLeft * 2);
        _cardFrame = CGRectMake(paddingLeft, paddingTop, width, width);
    }
    return _cardFrame;
}

- (JYFacialGestureDetector *)facialGesturesDetector
{
    if (!_facialGesturesDetector)
    {
        JYFacialGestureDetector *detector = [JYFacialGestureDetector new];
        detector.delegate = self;
        detector.detectLeftWink = YES;
        detector.detectRightWink = YES;

        _facialGesturesDetector = detector;
    }
    return _facialGesturesDetector;
}

- (void)_nope
{
    self.isListening = NO;
    [self.frontCard mdc_swipe:MDCSwipeDirectionLeft];
}

- (void)_wink
{
    self.isListening = NO;
    [self.frontCard mdc_swipe:MDCSwipeDirectionRight];
}

- (void)setFrontCard:(JYUserCard *)frontCard
{
    _frontCard = frontCard;
    if (frontCard)
    {
        self.currentUser = frontCard.user;
    }
    else
    {
        self.currentUser = nil;
    }
}

- (JYUserCard *)popCard
{
    if ([self.userList count] == 0)
    {
        return nil;
    }

    MDCSwipeToChooseViewOptions *options = [MDCSwipeToChooseViewOptions new];
    options.delegate = self;
    options.threshold = 120.f;
    options.likedText = NSLocalizedString(@"WINK", nil);
    options.nopeText = NSLocalizedString(@"NOPE", nil);

    JYUserCard *card = [[JYUserCard alloc] initWithFrame:self.cardFrame options:options];
    card.user = self.userList[0];

    [self.userList removeObjectAtIndex:0];
    return card;
}

- (void)_loadCards
{
    if (!self.frontCard)
    {
        if (self.backCard)
        {
            self.frontCard = self.backCard;
        }
        else
        {
            self.frontCard = [self popCard];
        }

        [self.view addSubview:self.frontCard];

        self.backCard = [self popCard];
        [self.view insertSubview:self.backCard belowSubview:self.frontCard];
    }
    else if (!self.backCard)
    {
         self.backCard = [self popCard];
        [self.view insertSubview:self.backCard belowSubview:self.frontCard];
    }

    self.isListening = NO;
    if (self.frontCard)
    {
        [self _startDetectorAwakeTimer];
    }
}

#pragma mark - Maintain Data

- (void)_receivedUserList:(NSArray *)userList
{
    if ([userList count] == 0)
    {
        if ([self.zip length] > 1)
        {
            // shorten zip for 1 char and try again, which will cause the server search in a larger geo range
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.zip deleteCharactersInRange:NSMakeRange([self.zip length] - 1, 1)];
                [self _fetchUsers];
            });
        }
        return;
    }

    // update minUserId
    // TODO: uncommnet below
//    JYUser *lastUser = (JYUser *)[userList lastObject];
//    self.minUserId = [lastUser.userId unsignedLongLongValue];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.userList addObjectsFromArray:userList];
        [self _loadCards];
        [self _showTips];
    });
}

#pragma mark - Network

- (void)_wink:(JYUser *)user
{
    if (!user)
    {
        return;
    }

    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"wink/create"];
    NSDictionary *parameters = [self _parametersForWinkingUser:user];

    __weak typeof(self) weakSelf = self;
    [manager POST:url
      parameters:parameters
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"POST wink success. that username = %@", user.username);
             [weakSelf _networkThreadEnd];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"POST wink fail. error = %@", error);
             [weakSelf _networkThreadEnd];
         }
     ];
}

- (NSDictionary *)_parametersForWinkingUser:(JYUser *)user
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    [parameters setObject:user.username forKey:@"fname"];
    [parameters setObject:@([user.userId unsignedLongLongValue]) forKey:@"fid"];
    [parameters setObject:[user.yrsNumber uint64Number] forKey:@"fyrs"];
    [parameters setObject:@([JYCredential current].yrsValue) forKey:@"yrs"];

    return parameters;
}

- (void)_fetchUsers
{
    if ([JYCredential current].tokenValidInSeconds <= 0)
    {
        __weak typeof(self) weakSelf = self;
        self.pendingAction = ^{
            [weakSelf _fetchUsers];
        };
        return;
    }
    self.pendingAction = nil;
    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"users"];
    NSDictionary *parameters = [self _parametersForFetchingUsers];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"GET users success. responseObject = %@", responseObject);

             NSMutableArray *userList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 NSError *error = nil;
                 JYUser *user = (JYUser *)[MTLJSONAdapter modelOfClass:JYUser.class fromJSONDictionary:dict error:&error];
                 [userList addObject:user];
             }
             [weakSelf _receivedUserList:userList];
             [weakSelf _networkThreadEnd];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"GET users fail. error = %@", error);
             [weakSelf _networkThreadEnd];
         }
     ];
}

- (NSDictionary *)_parametersForFetchingUsers
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:[self _sexualOrientation] forKey:@"sex"];
    [parameters setObject:@(self.minUserId) forKey:@"beforeid"];

    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [parameters setObject:delegate.locationManager.countryCode forKey:@"country"];

    if (!self.zip)
    {
        self.zip = [NSMutableString stringWithString:delegate.locationManager.zip];
    }
    [parameters setObject:self.zip forKey:@"zip"];

    NSLog(@"fetch users parameters: %@", parameters);
    return parameters;
}

- (NSString *)_sexualOrientation
{
    NSString *sex = @"0";
    uint64_t yrsValue = [JYCredential current].yrsValue;
    JYYRS *yrs = [JYYRS yrsWithValue:yrsValue];
    switch (yrs.sex)
    {
        case 0:
            sex = @"1";
            break;
        default:
            break;
    }
    return sex;
}

- (void)_networkThreadBegin
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)_networkThreadEnd
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - Tips

- (AMPopTip *)winkTip
{
    if (!_winkTip)
    {
        _winkTip = [AMPopTip popTip];
        _winkTip.entranceAnimation = AMPopTipEntranceAnimationScale;
        _winkTip.popoverColor = JoyyBlue;
        _winkTip.shouldDismissOnTap = YES;

        __weak typeof(self) weakSelf = self;
        _winkTip.dismissHandler = ^{
            [weakSelf _showNopeTip];
        };
    }
    return _winkTip;
}

- (AMPopTip *)nopeTip
{
    if (!_nopeTip)
    {
        _nopeTip = [AMPopTip popTip];
        _nopeTip.entranceAnimation = AMPopTipEntranceAnimationScale;
        _nopeTip.popoverColor = FlatYellowDark;
        _nopeTip.shouldDismissOnTap = YES;

        __weak typeof(self) weakSelf = self;
        _nopeTip.dismissHandler = ^{
            [weakSelf _turnOnDetector];
        };
    }
    return _nopeTip;
}

- (void)_showTips
{
    if ([JYManagementDataStore sharedInstance].didShowPeopleViewTips)
    {
        return;
    }
    [self _showWinkTip];
}

- (void)_showWinkTip
{
    NSString *text = NSLocalizedString(@"If you like someone, just do a right wink (right eye closed and left eye open). \n\r Next", nil);
    [self.winkTip showText:text direction:AMPopTipDirectionUp maxWidth:180 inView:self.view fromFrame:self.winkButton.frame duration:10];
}

- (void)_showNopeTip
{
    NSString *text = NSLocalizedString(@"If you don't like someone, do a left wink (left eye closed and right eye open) \n\r Start", nil);
    [self.nopeTip showText:text direction:AMPopTipDirectionUp maxWidth:180 inView:self.view fromFrame:self.nopeButton.frame duration:10];
    [JYManagementDataStore sharedInstance].didShowPeopleViewTips = YES;
}

@end
