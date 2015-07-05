//
//  JYMapDashBoardView.m
//  joyyios
//
//  Created by Ping Yang on 4/5/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <HMSegmentedControl/HMSegmentedControl.h>

#import "JYMapDashBoardView.h"
#import "JYButton.h"

@interface JYMapDashBoardView ()

@end


@implementation JYMapDashBoardView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self _commonInit];
    }
    return self;
}

- (void)setHidden:(BOOL)hide
{
    if (_hidden == hide)
    {
        return;
    }
    _hidden = hide;

    __weak typeof(self) weakSelf = self;
    if (_hidden)
    {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = weakSelf.frame;
            frame.origin.y += kMapDashBoardHeight;
            weakSelf.frame = frame;
        }];
    }
    else
    {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = weakSelf.frame;
            frame.origin.y -= kMapDashBoardHeight;
            weakSelf.frame = frame;
        }];
    }
}

- (void)_commonInit
{
    [self _createServiceCategorySelector];
    [self _createLocateButton];
}


- (void)_createServiceCategorySelector
{
    CGFloat y = CGRectGetHeight(self.frame) - kButtonDefaultHeight;
    CGFloat width = CGRectGetWidth(self.frame);
    NSString *assistant = NSLocalizedString(@"Assistant", nil);
    NSString *escort = NSLocalizedString(@"Escort", nil);
    NSString *massage = NSLocalizedString(@"Massage", nil);
    NSString *performer = NSLocalizedString(@"Performer", nil);

    HMSegmentedControl *segmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:@[assistant, escort, massage, performer]];
    segmentedControl.frame = CGRectMake(0, y, width, kButtonDefaultHeight);
    segmentedControl.selectedSegmentIndex = 1;
    [segmentedControl addTarget:self action:@selector(_segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:segmentedControl];
}

- (void)_segmentedControlValueChanged:(HMSegmentedControl *)segmentedControl
{
    [self.delegate didSelectSegment:segmentedControl.selectedSegmentIndex];
}

- (void)_createLocateButton
{
    CGRect frame = CGRectMake(CGRectGetMaxX(self.frame) - kButtonLocateDiameter - kMarginRight,
                              0,
                              kButtonLocateDiameter,
                              kButtonLocateDiameter);
    JYButton *locateButton = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
    locateButton.backgroundColor = [UIColor whiteColor];
    locateButton.borderColor = FlatGray;
    locateButton.borderWidth = 0.5;
    locateButton.cornerRadius = kButtonDefaultHeight / 2;
    locateButton.contentAnimateToColor = FlatWhite;
    locateButton.contentColor = JoyyBlueLight;
    locateButton.contentEdgeInsets = UIEdgeInsetsMake(5, 2, 2, 5);
    locateButton.foregroundAnimateToColor = JoyyBlueLight;
    locateButton.foregroundColor = [UIColor whiteColor];
    locateButton.imageView.image = [UIImage imageNamed:kImageNameLocationArrow];
    [locateButton addTarget:self action:@selector(_locateButtonPressed) forControlEvents:UIControlEventTouchUpInside];

    self.locateButton = locateButton;
    [self addSubview:self.locateButton];
}

- (void)_locateButtonPressed
{
    [self.delegate didPressLocateButton];
}

@end
