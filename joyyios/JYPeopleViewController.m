//
//  JYPeopleViewController.m
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "AppDelegate.h"
#import "JYButton.h"
#import "JYFacialGestureDetector.h"
#import "JYPeopleViewController.h"


@interface JYPeopleViewController () <JYFacialGuestureDetectorDelegate, JYPersonCardDelegate, MDCSwipeToChooseDelegate>
@property (nonatomic) CGRect frontCardFrame;
@property (nonatomic) CGRect backCardFrame;
@property (nonatomic) JYButton *nopeButton;
@property (nonatomic) JYButton *likeButton;
@property (nonatomic) NSInteger networkThreadCount;
@property (nonatomic) JYFacialGestureDetector *facialGesturesDetector;
@property (nonatomic) NSMutableArray *personList;
@property (nonatomic) BOOL isListening;
@end

static const CGFloat kButtonSpaceH = 80;
static const CGFloat kButtonSpaceV = 10;
static const CGFloat kButtonWidth = 60;

@implementation JYPeopleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = JoyyWhitePure;
    self.title = NSLocalizedString(@"People", nil);

    self.personList = [NSMutableArray new];
    self.isListening = NO;

    NSError *error;
    [self.facialGesturesDetector startDetectionWithError:&error];

    _frontCardFrame = CGRectZero;
    _backCardFrame = CGRectZero;

    [self.view addSubview:self.nopeButton];
    [self.view addSubview:self.likeButton];
//    [self _fetchPersonNearby];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self _fetchPersonNearby];

    self.isListening = YES;
    NSError *error;
    [self.facialGesturesDetector startDetectionWithError:&error];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.facialGesturesDetector stopDetection];
}

- (JYButton *)nopeButton
{
    if (!_nopeButton)
    {
        CGRect frame = CGRectMake(kButtonSpaceH, CGRectGetMaxY(self.backCardFrame) + kButtonSpaceV, kButtonWidth, kButtonWidth);
        UIImage *image = [UIImage imageNamed:@"nope"];
        _nopeButton = [JYButton circledButtonWithFrame:frame image:image color:FlatWatermelon];
        _nopeButton.borderWidth = 5;
        _nopeButton.borderColor = FlatWatermelon;
        _nopeButton.borderAnimateToColor = FlatWatermelon;
        _nopeButton.contentEdgeInsets = UIEdgeInsetsMake(3, 3, 3, 3);

        [_nopeButton addTarget:self action:@selector(_nope) forControlEvents:UIControlEventTouchUpInside];
    }
    return _nopeButton;
}

- (JYButton *)likeButton
{
    if (!_likeButton)
    {
        CGRect frame = CGRectMake(CGRectGetMaxX(self.view.frame) - kButtonWidth - kButtonSpaceH,
                                  CGRectGetMaxY(self.backCardFrame) + kButtonSpaceV,
                                  kButtonWidth,
                                  kButtonWidth);
        UIImage *image = [UIImage imageNamed:@"like"];
        _likeButton = [JYButton circledButtonWithFrame:frame image:image color:JoyyBlue];
        _likeButton.borderWidth = 5;
        _likeButton.borderColor = JoyyBlue;
        _likeButton.borderAnimateToColor = JoyyBlue;
        [_likeButton addTarget:self action:@selector(_like) forControlEvents:UIControlEventTouchUpInside];
    }
    return _likeButton;
}

- (CGRect)frontCardFrame
{
    if (_frontCardFrame.size.height == 0)
    {
        CGFloat paddingLeft = 10.f;
        CGFloat paddingTop = 84.f;

        CGFloat width = CGRectGetWidth(self.view.frame) - (paddingLeft * 2);
        _frontCardFrame = CGRectMake(paddingLeft, paddingTop, width, width);
    }
    return _frontCardFrame;
}

- (CGRect)backCardFrame
{
    if (_backCardFrame.size.height == 0)
    {
        return CGRectMake(self.frontCardFrame.origin.x,
                          self.frontCardFrame.origin.y,
                          CGRectGetWidth(self.frontCardFrame),
                          CGRectGetHeight(self.frontCardFrame));
    }
    return _backCardFrame;
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

#pragma mark - JYFacialDetectorDelegate Methods

- (void)detectorDidDetectLeftWink:(JYFacialGestureDetector *)detector
{
    self.isListening = NO;
    [self _nope];
}

- (void)detectorDidDetectRightWink:(JYFacialGestureDetector *)detector
{
    self.isListening = NO;
    [self _like];
}

#pragma mark - JYPersonCardDelegate

- (void)cardDidLoadImage:(JYPersonCard *)card
{
    // Listen for the first front card
    if (card == self.frontCard)
    {
        self.isListening = YES;
    }
}

#pragma mark - MDCSwipeToChooseDelegate Methods

// This is called when a user didn't fully swipe left or right.
- (void)viewDidCancelSwipe:(UIView *)view
{
//    NSLog(@"You couldn't decide on %@.", self.currentPerson.name);
}

// This is called then a user swipes the view fully left or right.
- (void)view:(UIView *)view wasChosenWithDirection:(MDCSwipeDirection)direction
{
    if (direction == MDCSwipeDirectionLeft)
    {
        NSLog(@"You noped %@.", self.currentPerson.username);
    }
    else
    {
        NSLog(@"You liked %@.", self.currentPerson.username);
    }

    // MDCSwipeToChooseView has removed the frontCard from the view hierarchy
    // after it is swiped. So, we move the backCard to the front, and create a new backCard.
    self.frontCard = self.backCard;
    self.isListening = (self.frontCard != nil);

    if ((self.backCard = [self popCardWithFrame:self.backCardFrame]))
    {
        [self.view insertSubview:self.backCard belowSubview:self.frontCard];
    }
}

#pragma mark View Handling

- (void)setFrontCard:(JYPersonCard *)frontCard
{
    _frontCard = frontCard;
    self.currentPerson = frontCard.person;
}

- (JYPersonCard *)popCardWithFrame:(CGRect)frame
{
    if ([self.personList count] == 0)
    {
        return nil;
    }

    MDCSwipeToChooseViewOptions *options = [MDCSwipeToChooseViewOptions new];
    options.delegate = self;
    options.threshold = 120.f;
    options.likedText = NSLocalizedString(@"LIKE", nil);
    options.nopeText = NSLocalizedString(@"NOPE", nil);
    options.onPan = ^(MDCPanState *state) {
        CGRect frame = self.backCardFrame;
        self.backCard.frame = CGRectMake(frame.origin.x,
                                         frame.origin.y - (state.thresholdRatio * 10.f),
                                         CGRectGetWidth(frame),
                                         CGRectGetHeight(frame));
    };

    JYPersonCard *card = [[JYPersonCard alloc] initWithFrame:frame options:options];
    card.delegate = self;
    card.person = self.personList[0];

    [self.personList removeObjectAtIndex:0];
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
            self.frontCard = [self popCardWithFrame:self.frontCardFrame];
        }

        [self.view addSubview:self.frontCard];

        self.backCard = [self popCardWithFrame:self.backCardFrame];
        [self.view insertSubview:self.backCard belowSubview:self.frontCard];
    }
    else if (!self.backCard)
    {
         self.backCard = [self popCardWithFrame:self.backCardFrame];
        [self.view insertSubview:self.backCard belowSubview:self.frontCard];
    }
}

- (void)_nope
{
    [self.frontCard mdc_swipe:MDCSwipeDirectionLeft];
}

- (void)_like
{
    [self.frontCard mdc_swipe:MDCSwipeDirectionRight];
}

#pragma mark - Maintain Data

- (void)_handleNearbyPersonIds:(NSArray *)personIds
{
    if (!personIds || personIds.count == 0)
    {
        return;
    }

    NSArray *validPersonIds = [self _filterPersonIds:personIds];
    [self _fetchPersonByIds:validPersonIds];
}

- (NSArray *)_filterPersonIds:(NSArray *)personIds
{
    NSMutableArray *validPersonIds = [NSMutableArray new];
    for (NSString *personId in personIds)
    {
        if ([self _isValid:personId])
        {
            [validPersonIds addObject:personId];
        }
    }
    return validPersonIds;
}

- (BOOL)_isValid:(NSString *)personId
{
    return YES;
}

#pragma mark - Network

- (void)_fetchPersonNearby
{
    if (self.networkThreadCount > 0)
    {
        return;
    }
    [self _networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"person/nearby"];
    NSDictionary *parameters = [self _parametersForPersonNearby];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"person/nearby fetch success responseObject: %@", responseObject);

             [weakSelf _handleNearbyPersonIds:responseObject];
             [weakSelf _networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [weakSelf _networkThreadEnd];
         }
     ];
}

- (NSDictionary *)_parametersForPersonNearby
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [parameters setObject:appDelegate.cellId forKey:@"cell"];

    if (self.personList.count > 0)
    {
        JYPerson *person = self.personList.lastObject;
        [parameters setValue:@(person.score) forKey:@"max"];
    }

//    NSLog(@"fetch person nearby parameters: %@", parameters);
    return parameters;
}

- (void)_fetchPersonByIds:(NSArray *)personIds
{
    [self _networkThreadBegin];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"person"];
    NSDictionary *parameters = @{@"id": personIds};

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"fetch person by ids success responseObject: %@", responseObject);

             for (NSDictionary *dict in responseObject)
             {
                 JYPerson *person = [[JYPerson alloc] initWithDictionary:dict];
                 [weakSelf.personList addObject:person];
             }
             [weakSelf _loadCards];
             [weakSelf _networkThreadEnd];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
