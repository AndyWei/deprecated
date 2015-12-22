//
//  JYJellyView.m
//  joyyios
//
//  Created by Ping Yang on 12/18/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYJellyView.h"

@interface JYJellyView ()
@property (nonatomic) CGFloat controlPointOffset;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat width;
@property (nonatomic) UIView *controlPoint;
@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) CAShapeLayer *shapeLayer;
@property (nonatomic) UICollisionBehavior *collisionBehavior;
@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) UISnapBehavior *snapBehavior;
@property (nonatomic) UIImageView *ballView;
@end

static NSString *const kBoundaryIdentifier = @"boundaryIdentifier";
static NSString *const kRotationIdentifier = @"rotationAnimation";

@implementation JYJellyView

- (instancetype)initWithFrame:(CGRect)frame
{
    CGRect viewFrame = frame;
    viewFrame.size.height =  frame.size.height + SCREEN_HEIGHT;
    if (self = [super initWithFrame:viewFrame])
    {
        self.height = frame.size.height;
        self.width = frame.size.width;
        self.isRefreshing = NO;
        self.backgroundColor = FlatGreen;

        [self addSubview:self.controlPoint];
        [self addSubview:self.ballView];

        self.shapeLayer = [CAShapeLayer layer];
        [self.layer insertSublayer:self.shapeLayer below:self.ballView.layer];
    }
    return self;
}

- (UIView *)controlPoint
{
    if (!_controlPoint)
    {
        _controlPoint = [[UIView alloc] initWithFrame:CGRectMake(self.width / 2, self.height, 10, 10)];
        _controlPoint.backgroundColor = FlatBlack;
    }
    return _controlPoint;
}

- (UIImageView *)ballView
{
    if (!_ballView)
    {
        _ballView = [[UIImageView alloc] initWithFrame:CGRectMake(self.width * 0.1, 0, 40, 40)];
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
    self.controlPoint.center = CGPointMake(self.width / 2 , self.controlPointOffset);

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, self.height)];
    [path addQuadCurveToPoint:CGPointMake(self.width, self.height) controlPoint:self.controlPoint.center];
    [path addLineToPoint:CGPointMake(self.width, 0)];
    [path addLineToPoint:CGPointMake(0, 0)];
    [path closePath];

    self.shapeLayer.path = path.CGPath;
    self.shapeLayer.fillColor = [UIColor redColor].CGColor;

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
        self.snapBehavior = [[ UISnapBehavior alloc] initWithItem:self.ballView snapToPoint:CGPointMake(self.width * 0.5, -50)];
        self.snapBehavior.damping = 1.0;
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
    rotationAnimation.duration = 0.9f;
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

-(void)_displayLinkAction:(CADisplayLink *)link
{
    CGFloat y = (-self.contentOffsetY - 80);
    self.controlPointOffset = fmax(y, 0);

    [self setNeedsDisplay];
}

@end
