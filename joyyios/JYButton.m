//
//  JYButton.m
//  joyyios
//
//  Forked and modified by Ping Yang on 3/27/15 from Github project: MRoundedButton
//  Below is the original license:

//  ---------------------------Begin of the original license--------------------
//  Copyright (c) 2014 Michael WU. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//  ---------------------------End of the original license--------------------

#import "JYButton.h"
#import <QuartzCore/QuartzCore.h>

CGFloat const JYButtonMaxValue = CGFLOAT_MAX;

#define JY_MAX_CORNER_RADIUS MIN(CGRectGetWidth(self.bounds) / 2.0, CGRectGetHeight(self.bounds) / 2.0)
#define JY_MAX_BORDER_WIDTH JY_MAX_CORNER_RADIUS
#define JY_MAGICAL_VALUE 0.29

#define JY_VERSION_IOS_8 (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)

#pragma mark - CGRect extend
static CGRect CGRectEdgeInset(CGRect rect, UIEdgeInsets insets)
{
    return CGRectMake(CGRectGetMinX(rect) + insets.left, CGRectGetMinY(rect) + insets.top, CGRectGetWidth(rect) - insets.left - insets.right,
                      CGRectGetHeight(rect) - insets.top - insets.bottom);
}

#pragma mark - JYButtonTextLayer
@interface JYButtonTextLayer : UIView

@property(nonatomic) UILabel *textLabel;

@end

@implementation JYButtonTextLayer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.adjustsFontSizeToFitWidth = NO;
        self.textLabel.minimumScaleFactor = 0.1;
        self.textLabel.numberOfLines = 1;
        if (JY_VERSION_IOS_8)
        {
            self.maskView = self.textLabel;
        }
        else
        {
            self.layer.mask = self.textLabel.layer;
        }
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.textLabel.frame = self.bounds;
}

@end

#pragma mark - JYButtonImageLayer
@interface JYButtonImageLayer : UIView

@property(nonatomic) UIImageView *imageView;

@end

@implementation JYButtonImageLayer

- (instancetype)initWithFrame:(CGRect)frame shouldMaskImage:(BOOL)mask
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.backgroundColor = [UIColor clearColor];
        if (mask)
        {
            if (JY_VERSION_IOS_8)
            {
                self.maskView = self.imageView;
            }
            else
            {
                self.layer.mask = self.imageView.layer;
            }
        }
        else
        {
            [self addSubview:self.imageView];
        }
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
}

@end

#pragma mark - MRoundedButton
@interface JYButton ()

@property(nonatomic) UIColor *backgroundColorCache;
@property(nonatomic, getter=isTrackingInside) BOOL trackingInside;
@property(nonatomic) UIView *foregroundView;
@property(nonatomic) JYButtonTextLayer *textLayer;
@property(nonatomic) JYButtonTextLayer *detailTextLayer;
@property(nonatomic) JYButtonTextLayer *topTextLayer;
@property(nonatomic) JYButtonImageLayer *imageLayer;

@end

@implementation JYButton

- (instancetype)initWithFrame:(CGRect)frame buttonStyle:(JYButtonStyle)style shouldMaskImage:(BOOL)mask appearanceIdentifier:(NSString *)identifier
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.layer.masksToBounds = YES;

        _buttonStyle = style;
        _contentColor = self.tintColor;
        _foregroundColor = [UIColor whiteColor];
        _restoreSelectedState = YES;
        _trackingInside = NO;
        _cornerRadius = 0.0;
        _borderWidth = 0.0;
        _contentEdgeInsets = UIEdgeInsetsZero;
        _shouldMaskImage = mask;

        self.foregroundView = [[UIView alloc] initWithFrame:CGRectNull];
        self.foregroundView.backgroundColor = self.foregroundColor;
        self.foregroundView.layer.masksToBounds = YES;
        [self addSubview:self.foregroundView];

        self.textLayer = [[JYButtonTextLayer alloc] initWithFrame:CGRectNull];
        self.textLayer.backgroundColor = self.contentColor;
        [self insertSubview:self.textLayer aboveSubview:self.foregroundView];

        self.detailTextLayer = [[JYButtonTextLayer alloc] initWithFrame:CGRectNull];
        self.detailTextLayer.backgroundColor = self.contentColor;
        [self insertSubview:self.detailTextLayer aboveSubview:self.foregroundView];

        self.topTextLayer = [[JYButtonTextLayer alloc] initWithFrame:CGRectNull];
        self.topTextLayer.backgroundColor = self.contentColor;
        [self insertSubview:self.topTextLayer aboveSubview:self.foregroundView];

        self.imageLayer = [[JYButtonImageLayer alloc] initWithFrame:CGRectNull shouldMaskImage:mask];
        self.imageLayer.backgroundColor = self.shouldMaskImage ? self.contentColor : self.foregroundColor;
        [self insertSubview:self.imageLayer aboveSubview:self.foregroundView];

        [self applyAppearanceForIdentifier:identifier];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame buttonStyle:(JYButtonStyle)style appearanceIdentifier:(NSString *)identifier
{
    return [[JYButton alloc] initWithFrame:frame buttonStyle:style shouldMaskImage:YES appearanceIdentifier:nil];
}

- (instancetype)initWithFrame:(CGRect)frame buttonStyle:(JYButtonStyle)style
{
    return [[JYButton alloc] initWithFrame:frame buttonStyle:style shouldMaskImage:YES appearanceIdentifier:nil];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [[JYButton alloc] initWithFrame:frame buttonStyle:JYButtonStyleDefault shouldMaskImage:YES appearanceIdentifier:nil];
}

+ (instancetype)button
{
    CGRect frame = CGRectMake(0, 0,  CGRectGetWidth([[UIScreen mainScreen] applicationFrame]), kButtonDefaultHeight);

    JYButton *button = [[JYButton alloc] initWithFrame:frame buttonStyle:JYButtonStyleDefault];
    button.backgroundColor = FlatWhite;
    button.contentAnimateToColor = FlatGray;
    button.contentColor = FlatWhite;
    button.foregroundColor = FlatSkyBlue;
    button.foregroundAnimateToColor = FlatWhite;
    button.textLabel.font = [UIFont boldSystemFontOfSize:kButtonDefaultFontSize];

    return button;
}

+ (instancetype)buttonWithFrame:(CGRect)frame buttonStyle:(JYButtonStyle)style appearanceIdentifier:(NSString *)identifier
{
    return [[JYButton alloc] initWithFrame:frame buttonStyle:style appearanceIdentifier:identifier];
}

+ (instancetype)buttonWithFrame:(CGRect)frame buttonStyle:(JYButtonStyle)style shouldMaskImage:(BOOL)mask appearanceIdentifier:(NSString *)identifier
{
    return [[JYButton alloc] initWithFrame:frame buttonStyle:style shouldMaskImage:mask appearanceIdentifier:identifier];
}

+ (instancetype)buttonWithFrame:(CGRect)frame buttonStyle:(JYButtonStyle)style shouldMaskImage:(BOOL)mask
{
    return [[JYButton alloc] initWithFrame:frame buttonStyle:style shouldMaskImage:mask appearanceIdentifier:nil];
}

- (CGRect)boxingRect
{
    CGRect internalRect = CGRectInset(self.bounds, self.layer.cornerRadius * JY_MAGICAL_VALUE + self.layer.borderWidth,
                                      self.layer.cornerRadius * JY_MAGICAL_VALUE + self.layer.borderWidth);
    return CGRectEdgeInset(internalRect, self.contentEdgeInsets);
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat cornerRadius = self.layer.cornerRadius = MAX(MIN(JY_MAX_CORNER_RADIUS, self.cornerRadius), 0);
    CGFloat borderWidth = self.layer.borderWidth = MAX(MIN(JY_MAX_BORDER_WIDTH, self.borderWidth), 0);

    _borderWidth = borderWidth;
    _cornerRadius = cornerRadius;

    CGFloat layoutBorderWidth = borderWidth == 0.0 ? 0.0 : borderWidth - 0.1;
    self.foregroundView.frame = CGRectMake(layoutBorderWidth, layoutBorderWidth, CGRectGetWidth(self.bounds) - layoutBorderWidth * 2,
                                           CGRectGetHeight(self.bounds) - layoutBorderWidth * 2);
    self.foregroundView.layer.cornerRadius = cornerRadius - borderWidth;

    CGRect boxRect = [self boxingRect];
    switch (self.buttonStyle)
    {
        case JYButtonStyleDefault:
            self.topTextLayer.frame = CGRectNull;
            self.imageLayer.frame = CGRectNull;
            self.detailTextLayer.frame = CGRectNull;
            self.textLayer.frame = [self boxingRect];
            break;

        case JYButtonStyleSubtitle:
            self.topTextLayer.frame = CGRectNull;
            self.imageLayer.frame = CGRectNull;
            self.textLayer.frame = CGRectMake(boxRect.origin.x, boxRect.origin.y, CGRectGetWidth(boxRect), CGRectGetHeight(boxRect) * 0.8);
            self.detailTextLayer.frame =
                CGRectMake(boxRect.origin.x, CGRectGetMaxY(self.textLayer.frame), CGRectGetWidth(boxRect), CGRectGetHeight(boxRect) * 0.2);
            break;

        case JYButtonStyleDate:
            self.imageLayer.frame = CGRectNull;

            CGFloat width = CGRectGetWidth(boxRect) * 0.5;
            CGFloat x = boxRect.origin.x + width * 0.5;

            self.topTextLayer.frame =
            CGRectMake(x, boxRect.origin.y, width, CGRectGetHeight(boxRect) * 0.15);

            CGFloat width2 = CGRectGetWidth(boxRect) * 0.7;
            CGFloat x2 = boxRect.origin.x + width * 0.15;
            self.textLayer.frame = CGRectMake(x2, CGRectGetMaxY(self.topTextLayer.frame), width2, CGRectGetHeight(boxRect) * 0.7);

            self.detailTextLayer.frame =
            CGRectMake(x, CGRectGetMaxY(self.textLayer.frame), width, CGRectGetHeight(boxRect) * 0.18);
            break;

        case JYButtonStyleCentralImage:
            self.topTextLayer.frame = CGRectNull;
            self.textLayer.frame = CGRectNull;
            self.detailTextLayer.frame = CGRectNull;
            self.imageLayer.frame = [self boxingRect];
            break;

        case JYButtonStyleImageWithTitle:
            self.topTextLayer.frame = CGRectNull;
            self.imageLayer.frame = CGRectMake(boxRect.origin.x, boxRect.origin.y, CGRectGetWidth(boxRect) * 0.05, CGRectGetHeight(boxRect));
            self.textLayer.frame =
                CGRectMake(CGRectGetMaxX(self.imageLayer.frame), boxRect.origin.y, CGRectGetWidth(boxRect) * 0.95, CGRectGetHeight(boxRect));
            self.detailTextLayer.frame = CGRectNull;
            break;

        case JYButtonStyleImageWithSubtitle:
        default:
            self.topTextLayer.frame = CGRectNull;
            self.textLayer.frame = CGRectNull;
            self.imageLayer.frame = CGRectMake(boxRect.origin.x, boxRect.origin.y, CGRectGetWidth(boxRect), CGRectGetHeight(boxRect) * 0.8);
            self.detailTextLayer.frame =
                CGRectMake(boxRect.origin.x, CGRectGetMaxY(self.imageLayer.frame), CGRectGetWidth(boxRect), CGRectGetHeight(boxRect) * 0.2);
            break;
    }
}

#pragma mark - Appearance
- (void)applyAppearanceForIdentifier:(NSString *)identifier
{
    if (![identifier length])
    {
        return;
    }

    NSDictionary *appearanceProxy = [JYButtonAppearanceManager appearanceForIdentifier:identifier];
    if (!appearanceProxy)
    {
        return;
    }

    [appearanceProxy enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key];
    }];
}

#pragma mark - Setter and getters
- (void)setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius == cornerRadius)
    {
        return;
    }

    _cornerRadius = cornerRadius;
    [self setNeedsLayout];
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    if (_borderWidth == borderWidth)
    {
        return;
    }

    _borderWidth = borderWidth;
    [self setNeedsLayout];
}

- (void)setBorderColor:(UIColor *)borderColor
{
    _borderColor = borderColor;
    self.layer.borderColor = borderColor.CGColor;
}

- (void)setContentColor:(UIColor *)contentColor
{
    _contentColor = contentColor;
    self.textLayer.backgroundColor = contentColor;
    self.detailTextLayer.backgroundColor = contentColor;
    self.topTextLayer.backgroundColor = contentColor;

    if (self.shouldMaskImage)
    {
        self.imageLayer.backgroundColor = contentColor;
    }
}

- (void)setForegroundColor:(UIColor *)foregroundColor
{
    _foregroundColor = foregroundColor;
    self.foregroundView.backgroundColor = foregroundColor;

    if (!self.shouldMaskImage)
    {
        self.imageLayer.backgroundColor = foregroundColor;
    }
}

- (UILabel *)textLabel
{
    return self.textLayer.textLabel;
}

- (UILabel *)detailTextLabel
{
    return self.detailTextLayer.textLabel;
}

- (UILabel *)topTextLabel
{
    return self.topTextLayer.textLabel;
}

- (UIImageView *)imageView
{
    return self.imageLayer.imageView;
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2
                     animations:^{
                         weakSelf.foregroundView.alpha = enabled ? 1.0 : 0.5;
                     }];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (selected)
    {
        [self fadeInAnimation];
    }
    else
    {
        [self fadeOutAnimation];
    }
}

#pragma mark - Fade animation
- (void)fadeInAnimation
{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2
                     animations:^{
                         if (weakSelf.contentAnimateToColor)
                         {
                             weakSelf.textLayer.backgroundColor = weakSelf.contentAnimateToColor;
                             weakSelf.detailTextLayer.backgroundColor = weakSelf.contentAnimateToColor;
                             weakSelf.topTextLayer.backgroundColor = weakSelf.contentAnimateToColor;
                             if (weakSelf.shouldMaskImage)
                             {
                                 weakSelf.imageLayer.backgroundColor = weakSelf.contentAnimateToColor;
                             }
                         }

                         if (weakSelf.borderAnimateToColor && weakSelf.foregroundAnimateToColor && weakSelf.borderAnimateToColor == weakSelf.foregroundAnimateToColor)
                         {
                             weakSelf.backgroundColorCache = weakSelf.backgroundColor;
                             weakSelf.foregroundView.backgroundColor = [UIColor clearColor];
                             weakSelf.backgroundColor = weakSelf.borderAnimateToColor;
                             return;
                         }

                         if (weakSelf.borderAnimateToColor)
                         {
                             weakSelf.layer.borderColor = weakSelf.borderAnimateToColor.CGColor;
                         }

                         if (weakSelf.foregroundAnimateToColor)
                         {
                             weakSelf.foregroundView.backgroundColor = weakSelf.foregroundAnimateToColor;
                             if (!weakSelf.shouldMaskImage)
                             {
                                 weakSelf.imageLayer.backgroundColor = weakSelf.foregroundAnimateToColor;
                             }
                         }
                     }];
}

- (void)fadeOutAnimation
{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2
                     animations:^{
                         weakSelf.textLayer.backgroundColor = weakSelf.contentColor;
                         weakSelf.detailTextLayer.backgroundColor = weakSelf.contentColor;
                         weakSelf.topTextLayer.backgroundColor = weakSelf.contentColor;
                         weakSelf.imageLayer.backgroundColor = weakSelf.shouldMaskImage ? weakSelf.contentColor : weakSelf.foregroundColor;

                         if (weakSelf.borderAnimateToColor && weakSelf.foregroundAnimateToColor && weakSelf.borderAnimateToColor == weakSelf.foregroundAnimateToColor)
                         {
                             weakSelf.foregroundView.backgroundColor = weakSelf.foregroundColor;
                             weakSelf.backgroundColor = weakSelf.backgroundColorCache;
                             weakSelf.backgroundColorCache = nil;
                             return;
                         }

                         weakSelf.foregroundView.backgroundColor = weakSelf.foregroundColor;
                         weakSelf.layer.borderColor = weakSelf.borderColor.CGColor;
                     }];
}

#pragma mark - Touchs
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *touchView = [super hitTest:point withEvent:event];
    if ([self pointInside:point withEvent:event])
    {
        return self;
    }

    return touchView;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    self.trackingInside = YES;
    self.selected = !self.selected;
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL wasTrackingInside = self.trackingInside;
    self.trackingInside = [self isTouchInside];

    if (wasTrackingInside && !self.isTrackingInside)
    {
        self.selected = !self.selected;
    }
    else if (!wasTrackingInside && self.isTrackingInside)
    {
        self.selected = !self.selected;
    }

    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    self.trackingInside = [self isTouchInside];
    if (self.isTrackingInside && self.restoreSelectedState)
    {
        self.selected = !self.selected;
    }

    self.trackingInside = NO;
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    self.trackingInside = [self isTouchInside];
    if (self.isTrackingInside)
    {
        self.selected = !self.selected;
    }

    self.trackingInside = NO;
    [super cancelTrackingWithEvent:event];
}

@end

#pragma mark - JYButtonAppearanceManager
NSString *const kJYButtonCornerRadius = @"cornerRadius";
NSString *const kJYButtonBorderWidth = @"borderWidth";
NSString *const kJYButtonBorderColor = @"borderColor";
NSString *const kJYButtonBorderAnimateToColor = @"borderAnimateToColor";
NSString *const kJYButtonContentColor = @"contentColor";
NSString *const kJYButtonContentAnimateToColor = @"contentAnimateToColor";
NSString *const kJYButtonForegroundColor = @"foregroundColor";
NSString *const kJYButtonForegroundAnimateToColor = @"foregroundAnimateToColor";
NSString *const kJYButtonRestoreSelectedState = @"restoreSelectedState";

@interface JYButtonAppearanceManager ()

@property(nonatomic) NSMutableDictionary *appearanceProxys;

@end

@implementation JYButtonAppearanceManager

+ (instancetype)sharedManager
{
    static JYButtonAppearanceManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [JYButtonAppearanceManager new];
    });

    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.appearanceProxys = @{}.mutableCopy;
    }

    return self;
}

+ (void)registerAppearanceProxy:(NSDictionary *)proxy forIdentifier:(NSString *)identifier
{
    if (!proxy || ![identifier length])
    {
        return;
    }

    JYButtonAppearanceManager *manager = [JYButtonAppearanceManager sharedManager];
    [manager.appearanceProxys setObject:proxy forKey:identifier];
}

+ (void)unregisterAppearanceProxyIdentier:(NSString *)identifier
{
    if (![identifier length])
    {
        return;
    }

    JYButtonAppearanceManager *manager = [JYButtonAppearanceManager sharedManager];
    [manager.appearanceProxys removeObjectForKey:identifier];
}

+ (NSDictionary *)appearanceForIdentifier:(NSString *)identifier
{
    return [[JYButtonAppearanceManager sharedManager].appearanceProxys objectForKey:identifier];
}

@end

#pragma mark - JYHollowBackgroundView
@implementation JYHollowBackgroundView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setForegroundColor:(UIColor *)foregroundColor
{
    if (_foregroundColor == foregroundColor)
    {
        return;
    }

    _foregroundColor = foregroundColor;
    [self setNeedsDisplay];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    [self.foregroundColor setFill];

    if (self.layer.masksToBounds)
    {
        UIBezierPath *rectPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius];
        CGContextAddPath(context, rectPath.CGPath);
    }
    else
    {
        UIBezierPath *rectPath = [UIBezierPath bezierPathWithRect:rect];
        CGContextAddPath(context, rectPath.CGPath);
    }

    [self.subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        if (view.layer.masksToBounds)
        {
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:view.frame cornerRadius:view.layer.cornerRadius];
            CGContextAddPath(context, path.CGPath);
        }
        else
        {
            UIBezierPath *path = [UIBezierPath bezierPathWithRect:view.frame];
            CGContextAddPath(context, path.CGPath);
        }
    }];

    CGContextEOFillPath(context);
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetShouldAntialias(context, YES);
    CGContextRestoreGState(context);
}

@end
