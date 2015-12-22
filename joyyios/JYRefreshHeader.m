//
//  JYRefreshHeader.m
//  joyyios
//
//  Created by Ping Yang on 12/21/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYJellyView.h"
#import "JYRefreshHeader.h"

@interface JYRefreshHeader ()
@property (nonatomic) BOOL needReset;
@property (nonatomic) JYJellyView *jellyView;

@end

static const CGFloat kHeight = 54;
static NSString *const kBoundaryIdentifier = @"boundaryIdentifier";
static NSString *const kRotationIdentifier = @"rotationAnimation";

@implementation JYRefreshHeader

- (void)prepare
{
    [super prepare];

    self.mj_h = kHeight;
    self.state = MJRefreshStateIdle;
    self.needReset = NO;
    self.backgroundColor = FlatGreen;

    [self addSubview:self.jellyView];
}

- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change
{
    [super scrollViewContentOffsetDidChange:change];

    CGPoint newPoint = [[change valueForKey:@"new"] CGPointValue];
    self.jellyView.contentOffsetY = newPoint.y;
}

- (void)setState:(MJRefreshState)state
{
    MJRefreshCheckState;

    self.jellyView.isRefreshing = NO;
    switch (state) {
        case MJRefreshStateIdle:
            self.needReset = YES;
            [self.jellyView stopJellyBounce];
            break;
        case MJRefreshStatePulling:
            [self.jellyView startJellyBounce];
            break;
        case MJRefreshStateRefreshing:
            self.jellyView.isRefreshing = YES;
            [self.jellyView startRotateBallView];
            break;
        default:
            break;
    }
}

- (void)setPullingPercent:(CGFloat)pullingPercent
{
    [super setPullingPercent:pullingPercent];
    if (pullingPercent == 0.0f)
    {
        [self _resetJellyView];
    }
}

- (JYJellyView *)jellyView
{
    if (!_jellyView)
    {
        _jellyView = [[JYJellyView alloc] initWithFrame:CGRectMake(0, -kHeight, SCREEN_WIDTH, kHeight)];
    }
    return _jellyView;
}

- (void)_resetJellyView
{
    if (!self.needReset)
    {
        return;
    }

    [self.jellyView stopRotateBallView];
    [self.jellyView stopSnap];
    [self.jellyView removeFromSuperview];
    self.jellyView = nil;
    [self addSubview:self.jellyView];

    self.needReset = NO;
}

@end
