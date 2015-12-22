//
//  JYJellyView.m
//  joyyios
//
//  Created by Ping Yang on 12/18/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYJellyView.h"

@interface JYJellyView ()
@property (nonatomic) BOOL needReset;
@property (nonatomic) CGFloat contentOffsetY;
@property (nonatomic) CGFloat controlPointOffset;
@property (nonatomic) UIView *controlPoint;
@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) CAShapeLayer *shapeLayer;
@property (nonatomic) UICollisionBehavior *collisionBehavior;
@property (nonatomic) UISnapBehavior *snapBehavior;
@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) UIImageView *ballView;
@end

static const CGFloat kOriginY = -50;
static const CGFloat kHeight = 54;
static NSString *const kBoundaryIdentifier = @"boundaryIdentifier";
static NSString *const kRotationIdentifier = @"rotationAnimation";

@implementation JYJellyView

- (UIView *)controlPoint
{
    if (!_controlPoint)
    {
        _controlPoint = [[UIView alloc] initWithFrame:CGRectMake(0, kOriginY, 10, 10)];
        _controlPoint.center = CGPointMake(SCREEN_WIDTH / 2, kHeight);
        _controlPoint.backgroundColor = FlatBlack;
    }
    return _controlPoint;
}

- (UIImageView *)ballView
{
    if (!_ballView)
    {
        _ballView = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH * 0.1, kOriginY, 40, 40)];
        _ballView.layer.cornerRadius = _ballView.bounds.size.width / 2;
        _ballView.image = [UIImage imageNamed:@"wink"];
        _ballView.backgroundColor = [UIColor clearColor];
    }
    return _ballView;
}

- (UIDynamicAnimator *)animator
{
    if (!_animator)
    {
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
        UIGravityBehavior *gravityBehavior = [[UIGravityBehavior alloc]initWithItems:@[self.ballView]];
        gravityBehavior.magnitude = 5;
        [_animator addBehavior:gravityBehavior];
    }
    return _animator;
}

- (UICollisionBehavior *)collisionBehavior
{
    if (!_collisionBehavior)
    {
        _collisionBehavior =  [[UICollisionBehavior alloc] initWithItems:@[self.ballView]];
    }
    return _collisionBehavior;
}

- (void)drawRect:(CGRect)rect
{
    self.controlPoint.center = CGPointMake(SCREEN_WIDTH / 2 , self.controlPointOffset);

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, kOriginY + kHeight)];
    [path addQuadCurveToPoint:CGPointMake(SCREEN_WIDTH, kOriginY + kHeight) controlPoint:self.controlPoint.center];
    [path addLineToPoint:CGPointMake(SCREEN_WIDTH, kOriginY)];
    [path addLineToPoint:CGPointMake(0, kOriginY)];
    [path closePath];

    self.shapeLayer.path = path.CGPath;
    self.shapeLayer.fillColor = [UIColor redColor].CGColor;

    if (self.state == MJRefreshStateRefreshing)
    {
        [self _startSnap];
    }
    else
    {
        [self.collisionBehavior removeBoundaryWithIdentifier:kBoundaryIdentifier];
        [self.animator removeBehavior:self.collisionBehavior];
        [self.collisionBehavior addBoundaryWithIdentifier:kBoundaryIdentifier forPath:path];
        [self.animator addBehavior:self.collisionBehavior];
    }
}

- (void)_resetViews
{
    if (!self.needReset)
    {
        return;
    }

    [self.ballView.layer removeAnimationForKey:kRotationIdentifier];
    [self _stopSnap];
    self.ballView.frame = CGRectMake(SCREEN_WIDTH * 0.1, kOriginY, 40, 40);

    [self.ballView removeFromSuperview];
    [self addSubview:self.ballView];

    if (self.shapeLayer)
    {
        [self.shapeLayer removeFromSuperlayer];
    }
    self.shapeLayer = [CAShapeLayer layer];
    [self.layer insertSublayer:self.shapeLayer below:self.ballView.layer];

    self.needReset = NO;
}

- (void)_startSnap
{
    if (!self.snapBehavior)
    {
        self.snapBehavior = [[ UISnapBehavior alloc] initWithItem:self.ballView snapToPoint:CGPointMake(SCREEN_WIDTH * 0.6, -50)];
        self.snapBehavior.damping = 1.0;
        [self.animator addBehavior:self.snapBehavior];
    }
}

- (void)_stopSnap
{
    if (self.snapBehavior)
    {
        [self.animator removeBehavior:self.snapBehavior];
        self.snapBehavior = nil;
    }
}

- (void)_startRotateBallView
{
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = @(M_PI * 2.0);
    rotationAnimation.duration = 0.9f;
    rotationAnimation.autoreverses = NO;
    rotationAnimation.repeatCount = HUGE_VALF;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [self.ballView.layer addAnimation:rotationAnimation forKey:kRotationIdentifier];
}

- (void)_startJellyBounce
{
    [self _stopJellyBounce];

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_displayLinkAction:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)_stopJellyBounce
{
    if (self.displayLink)
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

//持续刷新屏幕的计时器
-(void)_displayLinkAction:(CADisplayLink *)link
{
//    if (self.state == MJRefreshStateRefreshing)
//    {
//        self.controlPointOffset = self.controlPoint.layer.position.y - kHeight + kOriginY;
//    }
//    else
//    {
//         self.controlPointOffset = (-self.contentOffsetY - kJellyStartThreshold + kOriginY);
//    }

    CGFloat y = (-self.contentOffsetY - 80);
    self.controlPointOffset = fmax(y, 0);

    [self setNeedsDisplay];
}


- (void)prepare
{
    [super prepare];

    self.mj_h = kHeight;
    self.state = MJRefreshStateIdle;
    self.needReset = NO;
    self.backgroundColor = FlatGreen;

    [self addSubview:self.controlPoint];
    [self addSubview:self.ballView];

    self.shapeLayer = [CAShapeLayer layer];
    [self.layer insertSublayer:self.shapeLayer below:self.ballView.layer];
}

- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change
{
    [super scrollViewContentOffsetDidChange:change];

    CGPoint newPoint = [[change valueForKey:@"new"] CGPointValue];
    self.contentOffsetY = newPoint.y;
}

- (void)scrollViewContentSizeDidChange:(NSDictionary *)change
{
    [super scrollViewContentSizeDidChange:change];
}

- (void)scrollViewPanStateDidChange:(NSDictionary *)change
{
    [super scrollViewPanStateDidChange:change];
}

- (void)setState:(MJRefreshState)state
{
    MJRefreshCheckState;

    switch (state) {
        case MJRefreshStateIdle:
            self.needReset = YES;
            [self _stopJellyBounce];
            break;
        case MJRefreshStatePulling:
            [self _startJellyBounce];
            break;
        case MJRefreshStateRefreshing:
            [self _startRotateBallView];
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
        [self _resetViews];
    }
}

#pragma mark - UIScrollViewDelegate

@end
