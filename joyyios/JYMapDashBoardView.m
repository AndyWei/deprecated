//
//  JYMapDashBoardView.m
//  joyyios
//
//  Created by Ping Yang on 4/5/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYMapDashBoardView.h"
#import "MRoundedButton.h"

@interface JYMapDashBoardView ()

@property(nonatomic) JYMapDashBoardStyle style;

@end


@implementation JYMapDashBoardView

- (id)initWithFrame:(CGRect)frame withStyle:(JYMapDashBoardStyle)style
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _style = style;
        [self _createStartButton];
        [self _createEndButton];
        [self _createSubmitButton];
    }
    return self;
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
    CGFloat y = CGRectGetHeight(self.frame) - kMapDashBoardSubmitButtonHeight;
    CGRect frame = CGRectMake(0, y, CGRectGetWidth(self.frame), kMapDashBoardSubmitButtonHeight);

    self.submitButton = [[MRoundedButton alloc] initWithFrame:frame buttonStyle:MRoundedButtonDefault];
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

}

- (void)_createEndButton
{
    if (_style == JYMapDashBoardStyleStartOnly)
    {
        return;
    }
}

- (void)_submitButtonPressed
{
    if (self.delegate)
    {
        [self.delegate dashBoard:self submitButtonPressed:self.submitButton];
    }
}

- (void)_updateSubmitButton:(MapEditMode)mode
{
    NSString *text = nil;
    switch (mode)
    {
        case MapEditModeStartPoint:
            text = (_style == JYMapDashBoardStyleStartOnly)? NSLocalizedString(@"Set Sevice Location", nil) : NSLocalizedString(@"Set Pickup Location", nil);
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
