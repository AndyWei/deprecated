//
//  JYJellyView.m
//  joyyios
//
//  Created by Ping Yang on 12/18/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYJellyView.h"

@interface JYJellyView ()
@property (nonatomic) BOOL isFirstTime;
@property (nonatomic) CAShapeLayer *shapeLayer;
@property (nonatomic) UICollisionBehavior *collisionBehavior;
@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) UIImageView *ballView;
@end

static NSString *const kBoundaryIdentifier = @"boundaryIdentifier";

@implementation JYJellyView

- (id)initWithFrame:(CGRect)frame
{
    CGRect jellyFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height + [UIScreen mainScreen].bounds.size.height);

    if (self = [super initWithFrame:jellyFrame])
    {
        self.userFrame = frame;
        self.isLoading = NO;
        self.isFirstTime = NO;
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
        _controlPoint = [[UIView alloc]initWithFrame:CGRectMake(self.userFrame.size.width / 2 - 5, self.userFrame.size.height - 5, 10, 10)];
        _controlPoint.backgroundColor = [UIColor clearColor];
    }
    return _controlPoint;
}

- (UIImageView *)ballView
{
    if (!_ballView)
    {
        _ballView = [[UIImageView alloc]initWithFrame:CGRectMake(self.userFrame.size.width / 3 - 20, self.userFrame.size.height - 100, 40, 40)];
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
        _animator = [[UIDynamicAnimator alloc]initWithReferenceView:self];
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc]initWithItems:@[self.ballView]];
        gravity.magnitude = 2;
        [_animator addBehavior:gravity];

        UISnapBehavior *snap = [[ UISnapBehavior alloc]initWithItem:self.ballView snapToPoint:CGPointMake(self.userFrame.size.width / 2, self.userFrame.size.height - (130+64.5)/2)];
        [_animator addBehavior:snap];
    }
    return _animator;
}

- (UICollisionBehavior *)collisionBehavior
{
    if (!_collisionBehavior)
    {
        _collisionBehavior =  [[UICollisionBehavior alloc]initWithItems:@[self.ballView]];
    }
    return _collisionBehavior;
}

- (void)drawRect:(CGRect)rect
{
    if (self.isLoading == NO)
    {
        [self.collisionBehavior removeBoundaryWithIdentifier:kBoundaryIdentifier];
    }
    else if (!self.isFirstTime)
    {
        self.isFirstTime = YES;
        [self startLoading];
    }

    self.controlPoint.center = (self.isLoading == NO)?(CGPointMake(self.userFrame.size.width / 2 , self.userFrame.size.height + self.controlPointOffset)) : (CGPointMake(self.userFrame.size.width / 2, self.userFrame.size.height + self.controlPointOffset));

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0,self.userFrame.size.height)];
    [path addQuadCurveToPoint:CGPointMake(self.userFrame.size.width,self.userFrame.size.height) controlPoint:self.controlPoint.center];
    [path addLineToPoint:CGPointMake(self.userFrame.size.width, 0)];
    [path addLineToPoint:CGPointMake(0, 0)];
    [path closePath];

    self.shapeLayer.path = path.CGPath;
    self.shapeLayer.fillColor = [UIColor redColor].CGColor;

    if (self.isLoading == NO)
    {
        [self.collisionBehavior addBoundaryWithIdentifier:kBoundaryIdentifier forPath:path];
        [self.animator addBehavior:self.collisionBehavior];
    }
}

- (void)startLoading
{
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = @(M_PI * 2.0);
    rotationAnimation.duration = 0.9f;
    rotationAnimation.autoreverses = NO;
    rotationAnimation.repeatCount = HUGE_VALF;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [self.ballView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

@end
