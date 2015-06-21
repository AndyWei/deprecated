//
//  JYMapDashBoardView.m
//  joyyios
//
//  Created by Ping Yang on 4/5/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYMapDashBoardView.h"
#import "JYButton.h"

@interface JYMapDashBoardView ()

@property(nonatomic) JYMapDashBoardStyle dashBoardStyle;

@end


@implementation JYMapDashBoardView

- (instancetype)initWithFrame:(CGRect)frame withStyle:(JYMapDashBoardStyle)style
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.dashBoardStyle = style;
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.dashBoardStyle = JYMapDashBoardStyleStartOnly;
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.dashBoardStyle = JYMapDashBoardStyleStartOnly;
        [self _commonInit];
    }
    return self;
}

- (void)setMapEditMode:(MapEditMode)mode
{
    if (mode == _mapEditMode)
    {
        return;
    }

    [self _updateSubmitButton:mode];
    [self _updateAddressButtons:mode];

    _mapEditMode = mode;
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
    [self _createStartButton];
    [self _createEndButton];
    [self _createSubmitButton];
    [self _createLocateButton];
}

- (void)_createSubmitButton
{
    JYButton *button = [JYButton button];
    button.y = CGRectGetHeight(self.frame) - kButtonDefaultHeight;
    [button addTarget:self action:@selector(_submitButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.submitButton = button;
    [self addSubview:self.submitButton];
}

- (void)_createStartButton
{
    CGFloat totalWidth = CGRectGetWidth(self.frame);
    CGFloat width = (_dashBoardStyle == JYMapDashBoardStyleStartOnly)? totalWidth: totalWidth * 0.7;
    CGRect frame = CGRectMake(0,
                              CGRectGetHeight(self.frame) - 2 * kButtonDefaultHeight,
                              width,
                              kButtonDefaultHeight);
    JYButton *startButton = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleImageWithTitle shouldMaskImage:NO];
    startButton.backgroundColor = [UIColor whiteColor];
    startButton.contentColor = FlatBlack;
    startButton.foregroundAnimateToColor = FlatWhite;
    startButton.imageView.image = [UIImage imageNamed:kImageNamePinBlue];
    startButton.textLabel.font = [UIFont systemFontOfSize:kMapDashBoardLeadingFontSize];
    startButton.textLabel.text = NSLocalizedString(@"Add Start Address", nil);
    startButton.textLabel.textAlignment = NSTextAlignmentLeft;
    [startButton addTarget:self action:@selector(_startButtonPressed) forControlEvents:UIControlEventTouchUpInside];

    self.startButton = startButton;
    [self addSubview:self.startButton];
}

- (void)_createEndButton
{
    if (_dashBoardStyle == JYMapDashBoardStyleStartOnly)
    {
        return;
    }

    CGRect frame = CGRectMake(CGRectGetMaxX(self.startButton.frame),
                              CGRectGetMinY(self.startButton.frame),
                              CGRectGetWidth(self.frame) * 0.3,
                              CGRectGetHeight(self.startButton.frame));
    JYButton *endButton = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleImageWithTitle shouldMaskImage:NO];
    endButton.backgroundColor = [UIColor whiteColor];
    endButton.contentColor = FlatBlack;
    endButton.foregroundAnimateToColor = [UIColor whiteColor];
    endButton.foregroundColor = FlatWhite;
    endButton.imageView.image = [UIImage imageNamed:kImageNamePinPink];
    endButton.textLabel.text = NSLocalizedString(@"Add Destination", nil);
    endButton.textLabel.textAlignment = NSTextAlignmentLeft;
    [endButton addTarget:self action:@selector(_endButtonPressed) forControlEvents:UIControlEventTouchUpInside];

    self.endButton = endButton;
    [self addSubview:self.endButton];
}

- (void)_createLocateButton
{
    CGFloat margin = kMapDashBoardHeight - kButtonLocateDiameter - 2 * kButtonDefaultHeight;
    CGRect frame = CGRectMake(CGRectGetMaxX(self.frame) - kButtonLocateDiameter - margin,
                              0,
                              kButtonLocateDiameter,
                              kButtonLocateDiameter);
    JYButton *locateButton = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleCentralImage shouldMaskImage:YES];
    locateButton.backgroundColor = [UIColor whiteColor];
    locateButton.borderColor = FlatGray;
    locateButton.borderWidth = 0.5;
    locateButton.cornerRadius = kButtonDefaultHeight / 2;
    locateButton.contentAnimateToColor = FlatWhite;
    locateButton.contentColor = FlatSkyBlue;
    locateButton.contentEdgeInsets = UIEdgeInsetsMake(5, 2, 2, 5);
    locateButton.foregroundAnimateToColor = FlatSkyBlue;
    locateButton.foregroundColor = [UIColor whiteColor];
    locateButton.imageView.image = [UIImage imageNamed:kImageNameLocationArrow];
    [locateButton addTarget:self action:@selector(_locateButtonPressed) forControlEvents:UIControlEventTouchUpInside];

    self.locateButton = locateButton;
    [self addSubview:self.locateButton];
}

- (void)_submitButtonPressed
{
    if (self.delegate)
    {
        [self.delegate dashBoard:self submitButtonPressed:self.submitButton];
    }
}

- (void)_startButtonPressed
{
    if (self.delegate)
    {
        [self.delegate dashBoard:self startButtonPressed:self.startButton];
    }
}

- (void)_endButtonPressed
{
    if (self.delegate)
    {
        [self.delegate dashBoard:self endButtonPressed:self.endButton];
    }
}

- (void)_locateButtonPressed
{
    if (self.delegate)
    {
        [self.delegate dashBoard:self locateButtonPressed:self.locateButton];
    }
}

- (void)_updateSubmitButton:(MapEditMode)mode
{
    NSString *text = nil;
    switch (mode)
    {
        case MapEditModeStartPoint:
            text = (_dashBoardStyle == JYMapDashBoardStyleStartOnly)? NSLocalizedString(@"Set Sevice Location", nil) : NSLocalizedString(@"Set Pickup Location", nil);
            break;
        case MapEditModeEndPoint:
            text = NSLocalizedString(@"Set Destination Location", nil);
            break;
        case MapEditModeDone:
            text = NSLocalizedString(@"Next", nil);
            break;
        default:
            text = @"";
            break;
    }
    self.submitButton.textLabel.text = text;
}

- (void)_updateAddressButtons:(MapEditMode)mode
{
    if (_dashBoardStyle == JYMapDashBoardStyleStartOnly)
    {
        return;
    }

    __weak typeof(self) weakSelf = self;
    if (mode == MapEditModeStartPoint)
    {
        [UIView animateWithDuration:0.2f animations:^{
            weakSelf.startButton.foregroundColor = [UIColor whiteColor];
            weakSelf.startButton.textLabel.font = [UIFont systemFontOfSize:kMapDashBoardLeadingFontSize];
            weakSelf.startButton.frame = CGRectMake(CGRectGetMinX(weakSelf.startButton.frame),
                                                CGRectGetMinY(weakSelf.startButton.frame),
                                                CGRectGetWidth(weakSelf.frame) * 0.7,
                                                CGRectGetHeight(weakSelf.startButton.frame));

            weakSelf.endButton.foregroundColor = FlatWhite;
            weakSelf.endButton.textLabel.font = [UIFont systemFontOfSize:kMapDashBoardSupportingFontSize];
            weakSelf.endButton.frame = CGRectMake(CGRectGetWidth(weakSelf.frame) * 0.7,
                                              CGRectGetMinY(weakSelf.endButton.frame),
                                              CGRectGetWidth(weakSelf.frame) * 0.3,
                                              CGRectGetHeight(weakSelf.endButton.frame));
        }];
    }
    else if (mode == MapEditModeEndPoint)
    {
        NSAssert(weakSelf.endButton, @"endButton must not be nil in MapEditModeEndPoint mode");
        [UIView animateWithDuration:0.2f animations:^{
            weakSelf.endButton.foregroundColor = [UIColor whiteColor];
            weakSelf.endButton.textLabel.font = [UIFont systemFontOfSize:kMapDashBoardLeadingFontSize];
            weakSelf.endButton.frame = CGRectMake(CGRectGetWidth(weakSelf.frame) * 0.3,
                                              CGRectGetMinY(weakSelf.endButton.frame),
                                              CGRectGetWidth(weakSelf.frame) * 0.7,
                                              CGRectGetHeight(weakSelf.endButton.frame));

            weakSelf.startButton.foregroundColor = FlatWhite;
            weakSelf.startButton.textLabel.font = [UIFont systemFontOfSize:kMapDashBoardSupportingFontSize];
            weakSelf.startButton.frame = CGRectMake(CGRectGetMinX(weakSelf.startButton.frame),
                                                CGRectGetMinY(weakSelf.startButton.frame),
                                                CGRectGetWidth(weakSelf.frame) * 0.3,
                                                CGRectGetHeight(weakSelf.startButton.frame));
        }];
    }
    else if (mode == MapEditModeDone)
    {
        NSAssert(weakSelf.endButton, @"endButton must not be nil in MapEditModeDone mode");
        [UIView animateWithDuration:0.2f animations:^{
            weakSelf.startButton.foregroundColor = [UIColor whiteColor];
            weakSelf.startButton.textLabel.font = [UIFont systemFontOfSize:kMapDashBoardLeadingFontSize];
            weakSelf.startButton.frame = CGRectMake(CGRectGetMinX(weakSelf.startButton.frame),
                                                    CGRectGetMinY(weakSelf.startButton.frame),
                                                    CGRectGetWidth(weakSelf.frame) * 0.5,
                                                    CGRectGetHeight(weakSelf.startButton.frame));

            weakSelf.endButton.foregroundColor = [UIColor whiteColor];
            weakSelf.endButton.textLabel.font = [UIFont systemFontOfSize:kMapDashBoardLeadingFontSize];
            weakSelf.endButton.frame = CGRectMake(CGRectGetWidth(weakSelf.frame) * 0.5,
                                                  CGRectGetMinY(weakSelf.endButton.frame),
                                                  CGRectGetWidth(weakSelf.frame) * 0.5,
                                                  CGRectGetHeight(weakSelf.endButton.frame));
        }];
    }
}

@end
