//
//  JYJellyView.m
//  joyyios
//
//  Created by Ping Yang on 12/18/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYJellyView.h"

@interface JYJellyView ()
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat width;
@property (nonatomic) UIView *controlPoint;
@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) UICollisionBehavior *collisionBehavior;
@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) UIImageView *ballView;
@property (nonatomic) UISnapBehavior *snapBehavior;
@property (nonatomic) UIVisualEffectView *maskView;
@end

static NSString *const kBoundaryIdentifier = @"boundaryIdentifier";
static NSString *const kRotationIdentifier = @"rotationAnimation";

@implementation JYJellyView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.width = frame.size.width;
        self.height = frame.size.height;
        self.contentOffsetY = -frame.size.height;

        self.isRefreshing = NO;
        self.backgroundColor = ClearColor;

        [self addSubview:self.controlPoint];
        [self addSubview:self.maskView];
        [self addSubview:self.ballView];
        self.ballView.alpha = 0.0;
    }
    return self;
}

- (UIView *)controlPoint
{
    if (!_controlPoint)
    {
        _controlPoint = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        _controlPoint.center = CGPointMake(self.width / 2, self.height);
        _controlPoint.backgroundColor = ClearColor;
    }
    return _controlPoint;
}

- (UIImageView *)ballView
{
    if (!_ballView)
    {
        _ballView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _ballView.center = CGPointMake(self.width * 0.9, 0);
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
        gravityBehavior.magnitude = 20;
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

- (UIVisualEffectView *)maskView
{
    if (!_maskView)
    {
        UIBlurEffect* blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        _maskView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        _maskView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        _maskView.layer.masksToBounds = YES;
    }
    return _maskView;
}

- (UIBezierPath *)bezierPath
{
//    CGFloat y = self.fullMask? fmin(self.contentOffsetY, 0): 0;
    CGFloat y = 0;

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, self.height)];
    [path addQuadCurveToPoint:CGPointMake(self.width, self.height) controlPoint:self.controlPoint.center];
    [path addLineToPoint:CGPointMake(self.width, y)];
    [path addLineToPoint:CGPointMake(0, y)];
    [path closePath];

    return path;
}

- (void)drawRect:(CGRect)rect
{
    UIBezierPath *path = [self bezierPath];
    CAShapeLayer *shapeLayer = [CAShapeLayer new];
    shapeLayer.path = path.CGPath;
    self.maskView.layer.mask = shapeLayer;

    if (self.isRefreshing)
    {
        [self startSnap];
    }
    else
    {
        [self.collisionBehavior removeBoundaryWithIdentifier:kBoundaryIdentifier];
        [self.animator removeBehavior:self.collisionBehavior];
        [self.collisionBehavior addBoundaryWithIdentifier:kBoundaryIdentifier forPath:path];
        [self.animator addBehavior:self.collisionBehavior];
    }
}

- (void)startSnap
{
    if (!self.snapBehavior)
    {
        self.snapBehavior = [[ UISnapBehavior alloc] initWithItem:self.ballView snapToPoint:CGPointMake(self.width * 0.5, 20)];
        self.snapBehavior.damping = 0.5;
        [self.animator addBehavior:self.snapBehavior];
    }
}

- (void)stopSnap
{
    if (self.snapBehavior)
    {
        [self.animator removeBehavior:self.snapBehavior];
        self.snapBehavior = nil;
    }
}

- (void)startRotateBallView
{
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = @(M_PI * 2.0);
    rotationAnimation.duration = 0.4f;
    rotationAnimation.autoreverses = NO;
    rotationAnimation.repeatCount = HUGE_VALF;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [self.ballView.layer addAnimation:rotationAnimation forKey:kRotationIdentifier];
}

- (void)stopRotateBallView
{
    [self.ballView.layer removeAnimationForKey:kRotationIdentifier];
}

- (void)startJellyBounce
{
    [self stopJellyBounce];

    self.ballView.alpha = 1.0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_displayLinkAction:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopJellyBounce
{
    if (self.displayLink)
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)_displayLinkAction:(CADisplayLink *)link
{
    if (self.isRefreshing)
    {
        self.controlPoint.center = CGPointMake(self.width / 2, self.height);
    }
    else
    {
        CGFloat y = -self.contentOffsetY + 50;
        self.controlPoint.center = CGPointMake(self.width / 2 , fmax(y, 0));
    }

    [self setNeedsDisplay];
}

@end
