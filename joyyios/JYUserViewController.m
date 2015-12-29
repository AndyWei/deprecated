//
//  JYUserViewController.m
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <MSWeakTimer/MSWeakTimer.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "AppDelegate.h"
#import "JYButton.h"
#import "JYFacialGestureDetector.h"
#import "JYUserViewController.h"

@interface JYUserViewController () <JYFacialGuestureDetectorDelegate, MDCSwipeToChooseDelegate>
@property (nonatomic) CGRect cardFrame;
@property (nonatomic) JYButton *nopeButton;
@property (nonatomic) JYButton *winkButton;
@property (nonatomic) JYButton *fetchButton;

@property (nonatomic) JYFacialGestureDetector *facialGesturesDetector;
@property (nonatomic) MSWeakTimer *detectorAwakeTimer;
@property (nonatomic) BOOL isListening;

@property (nonatomic) NSMutableArray *userList;
@property (nonatomic) NSInteger networkThreadCount;
@end

const CGFloat kButtonSpaceH = 80;
const CGFloat kButtonSpaceV = 40;
const CGFloat kButtonWidth = 60;

@implementation JYUserViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = JoyyWhitePure;
    self.title = NSLocalizedString(@"Radar", nil);

    self.userList = [NSMutableArray new];

    _cardFrame = CGRectZero;

    [self.view addSubview:self.fetchButton];
    [self.view addSubview:self.nopeButton];
    [self.view addSubview:self.winkButton];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appStart) name:kNotificationAppDidStart object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appStop) name:kNotificationAppDidStop object:nil];

    [self _fetchUsers];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self _turnOnDetector];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (_facialGesturesDetector)
    {
        [self _turnOffDetector];
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
    // Since in the init few seconds the reportings from the detector is not accurate, we don't listening to them
    // Later the awake timer will enable the reporting

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
    self.detectorAwakeTimer = [MSWeakTimer scheduledTimerWithTimeInterval:2.0f
                                                            target:self
                                                          selector:@selector(_awakeDetector)
                                                          userInfo:nil
                                                           repeats:NO
                                                     dispatchQueue:queue];
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
//        NSLog(@"You liked %@.", self.currentPerson.username);
    }

    // MDCSwipeToChooseView has removed the frontCard from the view hierarchy
    // after it is swiped. So, we move the backCard to the front, and create a new backCard.
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

#pragma mark View Handling

- (JYButton *)fetchButton
{
    if (!_fetchButton)
    {
        _fetchButton = [JYButton button];
        _fetchButton.x = 50;
        _fetchButton.y = CGRectGetMidY(self.cardFrame);
        _fetchButton.width = SCREEN_WIDTH - 100;
        _fetchButton.cornerRadius = 5;

        _fetchButton.textLabel.text = NSLocalizedString(@"GET MORE PEOPLE", nil);
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
        _nopeButton = [JYButton iconButtonWithFrame:frame icon:image color:JoyyRed];
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
    self.currentUser = frontCard.user;
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

- (void)_handleNearbyUserIds:(NSArray *)userIds
{
    if (!userIds || userIds.count == 0)
    {
        return;
    }

    NSArray *validUserIds = [self _filterUserIds:userIds];
    [self _fetchPersonByIds:validUserIds];
}

- (NSArray *)_filterUserIds:(NSArray *)userIds
{
    NSMutableArray *validUserIds = [NSMutableArray new];
    for (NSString *userId in userIds)
    {
        if ([self _isValid:userId])
        {
            [validUserIds addObject:userId];
        }
    }
    return validUserIds;
}

- (BOOL)_isValid:(NSString *)userId
{
    return YES;
}

#pragma mark - Network

- (void)_fetchUsers
{
    if (self.networkThreadCount > 0)
    {
        return;
    }
    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"person/nearby"];
    NSDictionary *parameters = [self _parametersForPersonNearby];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(NSURLSessionTask *operation, id responseObject) {
//             NSLog(@"person/nearby fetch success responseObject: %@", responseObject);

             [weakSelf _handleNearbyUserIds:responseObject];
             [weakSelf _networkThreadEnd];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             [weakSelf _networkThreadEnd];
         }
     ];
}

- (NSDictionary *)_parametersForPersonNearby
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [parameters setObject:delegate.locationManager.zip forKey:@"zip"];

//    NSString *orientation = [JYUser me].sexualOrientation;
//    [parameters setObject:orientation forKey:@"orientation"];

    if (self.userList.count > 0)
    {
//        JYUser *person = self.userList.lastObject;
//        [parameters setValue:@(person.id) forKey:@"max"];
    }

//    NSLog(@"fetch person nearby parameters: %@", parameters);
    return parameters;
}

- (void)_fetchPersonByIds:(NSArray *)userIds
{
    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"person"];
    NSDictionary *parameters = @{@"id": userIds};

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"fetch person by ids success responseObject: %@", responseObject);

             for (NSDictionary *dict in responseObject)
             {
                 NSError *error = nil;
                 JYUser *user = (JYUser *)[MTLJSONAdapter modelOfClass:JYUser.class fromJSONDictionary:dict error:&error];
                 [weakSelf.userList addObject:user];
             }
             [weakSelf _loadCards];
             [weakSelf _networkThreadEnd];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             [weakSelf _networkThreadEnd];
         }
     ];
}

- (void)_networkThreadBegin
{
    if (self.networkThreadCount == 0)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    self.networkThreadCount++;
}

- (void)_networkThreadEnd
{
    self.networkThreadCount--;
    if (self.networkThreadCount <= 0)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

@end
