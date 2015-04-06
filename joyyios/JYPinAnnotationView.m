//
//  JYPinAnnotationView.m
//  joyyios
//
//  Created by Ping Yang on 4/2/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYPinAnnotationView.h"

@interface JYPinAnnotationView ()
{
    UIImageView *_annotationImageView;
}
@end

@implementation JYPinAnnotationView

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];

    if (self != nil)
    {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self != nil)
    {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit
{
    _pinColor = JYPinAnnotationColorNone;
    self.frame = CGRectMake(0.0f, 0.0f, kPinAnnotationWidth, kPinAnnotationHeight * 2);
    self.backgroundColor = [UIColor clearColor];
}

#pragma mark - Setters
- (void)setPinColor:(JYPinAnnotationColor)pinColor
{
    if (_pinColor == pinColor)
    {
        return;
    }

    _pinColor = pinColor;

    if (!_annotationImageView)
    {
        _annotationImageView = [[UIImageView alloc] initWithImage:[self annotationImage]];

        [self addSubview:_annotationImageView];
    }
    else
    {
        _annotationImageView.image = [self annotationImage];
    }
}

- (UIImage *)annotationImage
{
    UIImage *image = nil;

    switch (_pinColor)
    {
        case JYPinAnnotationColorBlue:
            image = [UIImage imageNamed:kImageNamePinBlue];
            break;
        case JYPinAnnotationColorGreen:
            image = [UIImage imageNamed:kImageNamePinGreen];
            break;
        case JYPinAnnotationColorPink:
            image = [UIImage imageNamed:kImageNamePinPink];
            break;
        default:
            image = [UIImage imageNamed:kImageNamePinBlue];
            break;
    }

    return image;
}

@end
