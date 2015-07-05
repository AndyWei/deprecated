//
//  JYSelectionViewController.m
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYSelectionViewController.h"

@interface JYSelectionViewController ()

@property (nonatomic, strong) NSMutableArray *joyyorList;

@end

static const CGFloat kHorizontalPadding = 80.f;
static const CGFloat kVerticalPadding = 20.f;

@implementation JYSelectionViewController

#pragma mark - Object Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _joyyorList = [[self defaultPeople] mutableCopy];
    }
    return self;
}

#pragma mark - UIViewController Overrides

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = JoyyWhite;
    self.frontCard = [self popJoyyorCardWithFrame:[self frontCardFrame]];
    [self.view addSubview:self.frontCard];

    self.backCard = [self popJoyyorCardWithFrame:[self backCardFrame]];
    [self.view insertSubview:self.backCard belowSubview:self.frontCard];

    [self _createNopeButton];
    [self _createLikedButton];
}

#pragma mark - MDCSwipeToChooseDelegate Protocol Methods

// This is called when a user didn't fully swipe left or right.
- (void)viewDidCancelSwipe:(UIView *)view
{
    NSLog(@"You couldn't decide on %@.", self.currentJoyyor.name);
}

// This is called then a user swipes the view fully left or right.
- (void)view:(UIView *)view wasChosenWithDirection:(MDCSwipeDirection)direction
{
    if (direction == MDCSwipeDirectionLeft)
    {
        NSLog(@"You noped %@.", self.currentJoyyor.name);
    } else {
        NSLog(@"You liked %@.", self.currentJoyyor.name);
    }

    // MDCSwipeToChooseView removes the view from the view hierarchy
    // after it is swiped (this behavior can be customized via the
    // MDCSwipeOptions class). Since the front card view is gone, we
    // move the back card to the front, and create a new back card.
    self.frontCard = self.backCard;
    if ((self.backCard = [self popJoyyorCardWithFrame:[self backCardFrame]])) {
        // Fade the back card into view.
        self.backCard.alpha = 0.f;
        [self.view insertSubview:self.backCard belowSubview:self.frontCard];
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.backCard.alpha = 1.f;
                         } completion:nil];
    }
}

#pragma mark - Internal Methods

- (void)setFrontCard:(JoyyorCard *)frontCard
{
    _frontCard = frontCard;
    self.currentJoyyor = frontCard.joyyor;
}

- (NSArray *)defaultPeople
{
    return @[
             [[Joyyor alloc] initWithName:@"Finn"
                                    image:[UIImage imageNamed:@"finn"]
                                      age:15
                    numberOfSharedFriends:3
                  numberOfSharedInterests:2
                           numberOfPhotos:1],
             [[Joyyor alloc] initWithName:@"Jake"
                                    image:[UIImage imageNamed:@"jake"]
                                      age:28
                    numberOfSharedFriends:2
                  numberOfSharedInterests:6
                           numberOfPhotos:8],
             [[Joyyor alloc] initWithName:@"Fiona"
                                    image:[UIImage imageNamed:@"fiona"]
                                      age:14
                    numberOfSharedFriends:1
                  numberOfSharedInterests:3
                           numberOfPhotos:5],
             ];
}

- (JoyyorCard *)popJoyyorCardWithFrame:(CGRect)frame
{
    if ([self.joyyorList count] == 0)
    {
        return nil;
    }

    MDCSwipeToChooseViewOptions *options = [MDCSwipeToChooseViewOptions new];
    options.delegate = self;
    options.threshold = 160.f;
    options.likedText = NSLocalizedString(@"LIKE", nil);
    options.nopeText = NSLocalizedString(@"NOPE", nil);
    options.onPan = ^(MDCPanState *state)
    {
        CGRect frame = [self backCardFrame];
        self.backCard.frame = CGRectMake(frame.origin.x,
                                             frame.origin.y - (state.thresholdRatio * 10.f),
                                             CGRectGetWidth(frame),
                                             CGRectGetHeight(frame));
    };

    JoyyorCard *personView = [[JoyyorCard alloc] initWithFrame:frame
                                                                    joyyor:self.joyyorList[0]
                                                                   options:options];
    [self.joyyorList removeObjectAtIndex:0];
    return personView;
}

#pragma mark View Contruction

- (CGRect)frontCardFrame
{
    CGFloat horizontalPadding = 20.f;
    CGFloat topPadding = 60.f;
    CGFloat bottomPadding = 200.f;
    return CGRectMake(horizontalPadding,
                      topPadding,
                      CGRectGetWidth(self.view.frame) - (horizontalPadding * 2),
                      CGRectGetHeight(self.view.frame) - bottomPadding);
}

- (CGRect)backCardFrame
{
    CGRect frontFrame = [self frontCardFrame];
    return CGRectMake(frontFrame.origin.x,
                      frontFrame.origin.y + 10.f,
                      CGRectGetWidth(frontFrame),
                      CGRectGetHeight(frontFrame));
}

// Create and add the "nope" button.
- (void)_createNopeButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    UIImage *image = [UIImage imageNamed:@"nope"];
    button.frame = CGRectMake(kHorizontalPadding,
                              CGRectGetMaxY(self.backCard.frame) + kVerticalPadding,
                              image.size.width,
                              image.size.height);
    [button setImage:image forState:UIControlStateNormal];
    [button setTintColor:[UIColor colorWithRed:247.f/255.f
                                         green:91.f/255.f
                                          blue:37.f/255.f
                                         alpha:1.f]];
    [button addTarget:self
               action:@selector(_nopeFrontCard)
     forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

// Create and add the "like" button.
- (void)_createLikedButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    UIImage *image = [UIImage imageNamed:@"like"];
    button.frame = CGRectMake(CGRectGetMaxX(self.view.frame) - image.size.width - kHorizontalPadding,
                              CGRectGetMaxY(self.backCard.frame) + kVerticalPadding,
                              image.size.width,
                              image.size.height);
    [button setImage:image forState:UIControlStateNormal];
    [button setTintColor:[UIColor colorWithRed:29.f/255.f
                                         green:245.f/255.f
                                          blue:106.f/255.f
                                         alpha:1.f]];
    [button addTarget:self
               action:@selector(_likeFrontCard)
     forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

#pragma mark Control Events

- (void)_nopeFrontCard
{
    [self.frontCard mdc_swipe:MDCSwipeDirectionLeft];
}

- (void)_likeFrontCard
{
    [self.frontCard mdc_swipe:MDCSwipeDirectionRight];
}

@end
