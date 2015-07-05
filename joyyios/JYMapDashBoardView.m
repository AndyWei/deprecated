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
    [self _createSubmitButton];
    [self _createLocateButton];
}

- (void)_createSubmitButton
{
    JYButton *button = [JYButton button];
    button.y = CGRectGetHeight(self.frame) - kButtonDefaultHeight;
    [button addTarget:self action:@selector(_submitButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    button.textLabel.text = NSLocalizedString(@"Set Sevice Location", nil);
    self.submitButton = button;
    [self addSubview:self.submitButton];
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

- (void)_locateButtonPressed
{
    if (self.delegate)
    {
        [self.delegate dashBoard:self locateButtonPressed:self.locateButton];
    }
}

@end
