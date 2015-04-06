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
        _dashBoardStyle = style;
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _dashBoardStyle = JYMapDashBoardStyleStartOnly;
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _dashBoardStyle = JYMapDashBoardStyleStartOnly;
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit
{
    [self _createStartButton];
    [self _createEndButton];
    [self _createSubmitButton];
}

- (void)setMapEditMode:(MapEditMode)mode
{
    [self _updateSubmitButton:mode];
    [self _updateStartButton:mode];
    [self _updateEndButton:mode];

    _mapEditMode = mode;
}

- (void)_createSubmitButton
{
    if (self.submitButton)
    {
        return;
    }

    CGFloat y = CGRectGetHeight(self.frame) - kMapDashBoardSubmitButtonHeight;
    CGRect frame = CGRectMake(0, y, CGRectGetWidth(self.frame), kMapDashBoardSubmitButtonHeight);

    self.submitButton = [[JYButton alloc] initWithFrame:frame buttonStyle:JYButtonStyleDefault];
    self.submitButton.contentAnimateToColor = FlatGray;
    self.submitButton.contentColor = FlatWhite;
    self.submitButton.foregroundColor = JoyyBlue;
    self.submitButton.foregroundAnimateToColor = FlatWhite;
    self.submitButton.textLabel.font = [UIFont boldSystemFontOfSize:kSignFieldFontSize];

    [self.submitButton addTarget:self action:@selector(_submitButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.submitButton];
}

- (void)_createStartButton
{
    if (self.startButton)
    {
        return;
    }

    CGFloat totalWidth = CGRectGetWidth(self.frame);
    CGFloat width = (_dashBoardStyle == JYMapDashBoardStyleStartOnly)? totalWidth: totalWidth * 0.7;
    CGRect frame = CGRectMake(0,
                              CGRectGetHeight(self.frame) - kMapDashBoardSubmitButtonHeight - kButtonDefaultHeight,
                              width,
                              kButtonDefaultHeight);
    self.startButton = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleImageWithTitle shouldMaskImage:NO];

    self.startButton.contentColor = FlatBlack;
    self.startButton.foregroundAnimateToColor = FlatWhite;
    self.startButton.imageView.image = [UIImage imageNamed:kImageNamePinBlue];
    self.startButton.textLabel.font = [UIFont systemFontOfSize:kMapDashBoardLeadingFontSize];
    self.startButton.textLabel.text = NSLocalizedString(@"Add Start Address", nil);
    self.startButton.textLabel.textAlignment = NSTextAlignmentLeft;

    [self.startButton addTarget:self action:@selector(_startButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.startButton];
}

- (void)_createEndButton
{
    if (self.endButton)
    {
        return;
    }

    if (_dashBoardStyle == JYMapDashBoardStyleStartOnly)
    {
        return;
    }

    CGRect frame = CGRectMake(CGRectGetWidth(self.startButton.frame),
                              CGRectGetHeight(self.frame) - kMapDashBoardSubmitButtonHeight - kButtonDefaultHeight,
                              CGRectGetWidth(self.frame) * 0.3,
                              kButtonDefaultHeight);
    self.endButton = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleImageWithTitle shouldMaskImage:NO];
    self.endButton.contentColor = FlatBlack;
    self.endButton.foregroundAnimateToColor = [UIColor whiteColor];
    self.endButton.foregroundColor = FlatWhite;
    self.endButton.imageView.image = [UIImage imageNamed:kImageNamePinPink];
    self.endButton.textLabel.font = [UIFont italicSystemFontOfSize:kMapDashBoardSupportingFontSize];
    self.endButton.textLabel.text = NSLocalizedString(@"Add Destination", nil);
    self.endButton.textLabel.textAlignment = NSTextAlignmentLeft;

    [self.endButton addTarget:self action:@selector(_endButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.endButton];
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

- (void)_updateStartButton:(MapEditMode)mode
{
    
}

- (void)_updateEndButton:(MapEditMode)mode
{

}
@end
