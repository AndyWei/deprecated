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
@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) CAShapeLayer *shapeLayer;
@property (nonatomic) UICollisionBehavior *collisionBehavior;
@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) UIImageView *ballView;
@end

static const CGFloat kJellyHeaderHeight = 300;
static const CGFloat kJellyStartThreshold = 64.5;
static const CGFloat kJellyLenth = 80;
static NSString *const kBoundaryIdentifier = @"boundaryIdentifier";

@implementation JYJellyView

//- (id)initWithFrame:(CGRect)frame
//{
//    CGRect jellyFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height + [UIScreen mainScreen].bounds.size.height);
//
//    if (self = [super initWithFrame:jellyFrame])
//    {
//        self.userFrame = frame;
//        self.isLoading = NO;
//        self.isFirstTime = NO;
//        [self addSubview:self.controlPoint];
//        [self addSubview:self.ballView];
//
//        self.shapeLayer = [CAShapeLayer layer];
//        [self.layer insertSublayer:self.shapeLayer below:self.ballView.layer];
//    }
//    return self;
//}

- (UIView *)controlPoint
{
    if (!_controlPoint)
    {
        _controlPoint = [[UIView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 5, kJellyHeaderHeight - 5, 10, 10)];
        _controlPoint.backgroundColor = [UIColor clearColor];
    }
    return _controlPoint;
}

- (UIImageView *)ballView
{
    if (!_ballView)
    {
        _ballView = [[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH / 3 - 20, kJellyHeaderHeight - 100, 40, 40)];
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

        UISnapBehavior *snap = [[ UISnapBehavior alloc]initWithItem:self.ballView snapToPoint:CGPointMake(SCREEN_WIDTH / 2, self.userFrame.size.height - (130+64.5)/2)];
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
    if (self.state != MJRefreshStateRefreshing)
    {
        [self.collisionBehavior removeBoundaryWithIdentifier:kBoundaryIdentifier];
    }
    else if (!self.isFirstTime)
    {
        self.isFirstTime = YES;
        [self _startRotateBallView];
    }

    self.controlPoint.center = (self.state != MJRefreshStateRefreshing)?(CGPointMake(self.userFrame.size.width / 2 , self.userFrame.size.height + self.controlPointOffset)) : (CGPointMake(self.userFrame.size.width / 2, self.userFrame.size.height + self.controlPointOffset));

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0,self.userFrame.size.height)];
    [path addQuadCurveToPoint:CGPointMake(self.userFrame.size.width,self.userFrame.size.height) controlPoint:self.controlPoint.center];
    [path addLineToPoint:CGPointMake(self.userFrame.size.width, 0)];
    [path addLineToPoint:CGPointMake(0, 0)];
    [path closePath];

    self.shapeLayer.path = path.CGPath;
    self.shapeLayer.fillColor = [UIColor redColor].CGColor;

    if (self.state != MJRefreshStateRefreshing)
    {
        [self.collisionBehavior addBoundaryWithIdentifier:kBoundaryIdentifier forPath:path];
        [self.animator addBehavior:self.collisionBehavior];
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
    [self.ballView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

#pragma mark 在这里做一些初始化配置（比如添加子控件）
- (void)prepare
{
    [super prepare];

    // 设置控件的高度
    self.mj_h = kJellyHeaderHeight;
    self.isFirstTime = NO;
    [self addSubview:self.controlPoint];
    [self addSubview:self.ballView];

    self.shapeLayer = [CAShapeLayer layer];
    [self.layer insertSublayer:self.shapeLayer below:self.ballView.layer];
}

#pragma mark 在这里设置子控件的位置和尺寸
- (void)placeSubviews
{
    [super placeSubviews];

    self.userFrame = self.bounds;
}

#pragma mark 监听scrollView的contentOffset改变
- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change
{
    [super scrollViewContentOffsetDidChange:change];
}

#pragma mark 监听scrollView的contentSize改变
- (void)scrollViewContentSizeDidChange:(NSDictionary *)change
{
    [super scrollViewContentSizeDidChange:change];
}

#pragma mark 监听scrollView的拖拽状态改变
- (void)scrollViewPanStateDidChange:(NSDictionary *)change
{
    [super scrollViewPanStateDidChange:change];
}

#pragma mark 监听控件的刷新状态
- (void)setState:(MJRefreshState)state
{
    MJRefreshCheckState;

    switch (state) {
        case MJRefreshStateIdle:
            [self.layer removeAnimationForKey:@"rotationAnimation"];
            break;
        case MJRefreshStatePulling:
            [self.loading stopAnimating];

            self.label.text = @"赶紧放开我吧(开关是打酱油滴)";
            break;
        case MJRefreshStateRefreshing:

            self.label.text = @"加载数据中(开关是打酱油滴)";
            [self.loading startAnimating];
            break;
        default:
            break;
    }
}

#pragma mark 监听拖拽比例（控件被拖出来的比例）
- (void)setPullingPercent:(CGFloat)pullingPercent
{
    [super setPullingPercent:pullingPercent];

    // 1.0 0.5 0.0
    // 0.5 0.0 0.5
    CGFloat red = 1.0 - pullingPercent * 0.5;
    CGFloat green = 0.5 - 0.5 * pullingPercent;
    CGFloat blue = 0.5 * pullingPercent;
    self.label.textColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offset = -scrollView.contentOffset.y;
    if (offset < kJellyStartThreshold)
    {
        if (self.jellyView.isLoading == NO)
        {
            [self _removeJellyView];
        }
        return;
    }

    if (!self.displayLink && offset > kJellyStartThreshold)
    {
        self.jellyView = [[JYJellyView alloc]initWithFrame:CGRectMake(0, -kJellyHeaderHeight, SCREEN_WIDTH, kJellyHeaderHeight)];
        self.jellyView.backgroundColor = [UIColor clearColor];
        [self.view insertSubview:self.jellyView aboveSubview:self.tableView];

        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_displayLinkAction:)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    else if (offset < kJellyStartThreshold)
    {
        [self _removeJellyView];
    }
}

//松手的时候
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    CGFloat offset = -scrollView.contentOffset.y;
    if (offset >= kJellyStartThreshold + kJellyLenth)
    {
        self.jellyView.isLoading = YES;

        [UIView animateWithDuration:0.3 delay:0.0f usingSpringWithDamping:0.4f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{

            self.jellyView.controlPoint.center = CGPointMake(self.jellyView.userFrame.size.width / 2, kJellyHeaderHeight);
            NSLog(@"self.jellyView.controlPoint.center:%@", NSStringFromCGPoint(self.jellyView.controlPoint.center));

            self.tableView.contentInset = UIEdgeInsetsMake(kJellyLenth+kJellyStartThreshold, 0, 0, 0);
        } completion:^(BOOL finished) {
            [self performSelector:@selector(backToTop) withObject:nil afterDelay:2.0f];
        }];
    }
}

//动画结束，删除一切
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.jellyView.isLoading == NO)
    {
        [self _removeJellyView];
    }
}

//跳到顶部的方法
-(void)backToTop
{
    [self.jellyView.layer removeAnimationForKey:@"rotationAnimation"];
    [UIView animateWithDuration:0.3 delay:0.0f usingSpringWithDamping:0.4f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.tableView.contentInset = UIEdgeInsetsMake(kJellyStartThreshold, 0, 0, 0);
    } completion:^(BOOL finished) {
        self.jellyView.isLoading = NO;
        [self _removeJellyView];
    }];
}

//持续刷新屏幕的计时器
-(void)_displayLinkAction:(CADisplayLink *)link
{
    self.jellyView.controlPointOffset = (self.jellyView.isLoading == NO)? (-self.tableView.contentOffset.y - kJellyStartThreshold) : (self.jellyView.controlPoint.layer.position.y - self.jellyView.userFrame.size.height);
    [self.jellyView setNeedsDisplay];
}

- (void)_removeJellyView
{
    [self.jellyView removeFromSuperview];
    self.jellyView = nil;
    [self.displayLink invalidate];
    self.displayLink = nil;
}

@end
